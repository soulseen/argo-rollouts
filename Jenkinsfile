pipeline {
    agent {
        docker {
            image "harbor.shopeemobile.com/devops-sz/cloud-native-client-tools"
            label "slave-nonlive"
            args "-u root --privileged "
        }
    }

    parameters {
        string(name:'RELEASE_TAG',defaultValue: '',description:'')
    }

    environment {
        KUBECONFIG_CLUSTER_SG2_TEST = credentials('56f51c07-a31a-45ca-a3d5-28ea2de6290e')
        NOTIFY_URL = 'https://openapi.seatalk.io/webhook/group/yrJzQ6HfR1Wxuyaak4C5qw'
        NOTIFY_EMAILS = '["xiaoyang.zhu@shopee.com"]'
    }

    stages {
        stage ('clone') {
            when {
                expression { env.gitlabTargetBranch == 'master' }
            }
            steps {
                gitlabBuilds(builds: ["clone"]) {
                    gitlabCommitStatus(name: "clone") {
                        checkout([
                            $class: 'GitSCM',
                            branches: [[name: env.gitlabSourceBranch]],
                            userRemoteConfigs: [[url: env.gitlabSourceRepoSSHUrl]]
                        ])
                    }
                }
            }
        }

        stage ('check-merge') {
            when {
                allOf {
                    expression { env.gitlabTargetBranch == 'master' }
                    expression { env.gitlabActionType == 'MERGE' }
                }
            }
            steps {
                gitlabBuilds(builds: ["merge"]) {
                    gitlabCommitStatus(name: "merge") {
                        sh 'git merge ${GIT_BRANCH}'
                    }
                }
            }
        }

        stage ('Unit test') {
            when {
                allOf {
                    expression { env.gitlabTargetBranch == 'master' }
                    expression { env.gitlabActionType == 'MERGE' }
                }
            }
            steps {
                gitlabBuilds(builds: ["Unit test"]) {
                    gitlabCommitStatus(name: "Unit test") {
                        sh 'make test'
                    }
                }
            }
        }

        stage ('e2e test') {
            when {
                allOf {
                    expression { env.gitlabTargetBranch == 'master' }
                    expression { env.gitlabActionType == 'MERGE' }
                }
            }
            steps {
                gitlabBuilds(builds: ["e2e test"]) {
                    gitlabCommitStatus(name: "e2e test") {
                        sh 'echo skiped'
                    }
                }
            }
        }

        stage ('image build and push') {
            when {
                allOf {
                    expression { env.gitlabTargetBranch == 'master' }
                    expression { env.gitlabActionType == 'MERGE' }
                }
            }
            steps {
                gitlabBuilds(builds: ["image build and push"]) {
                    gitlabCommitStatus(name: "image build and push") {
                        sh 'make image'
                        sh 'make image-push'
                    }
                }
            }
        }

        stage('push with release tag'){
            when {
                allOf {
                    expression { env.gitlabTargetBranch == 'master' }
                    expression { return params.RELEASE_TAG =~ /v.*/ }
                }
            }
            steps {
                sh 'make image-release-tag RELEASE_TAG=$RELEASE_TAG'
                sh 'make image-release-push RELEASE_TAG=$RELEASE_TAG'
            }
        }

        stage ('Deploy to production') {
            when {
                allOf {
                    expression { env.gitlabTargetBranch == 'master' }
                    expression { return params.RELEASE_TAG =~ /v.*/ }
                }
            }
            // Now deploy to sg2-test cluster only.
            steps {
                script {
                    try {
                        gitlabBuilds(builds: ["Deploy"]) {
                            sh "sed -i.bak 's#ImageTag#$RELEASE_TAG#' ./config/samples/git-secret/*.yaml"

                            sh """curl -X POST $env.NOTIFY_URL -d '{"tag":"text","text":{"content":"\\nrollout controller is deploying.","mentioned_email_list":$env.NOTIFY_EMAILS,"at_all":false}}'"""

                            sh "kubectl create ns argo-rollouts --dry-run -o yaml | kubectl apply -f -"
                            gitlabCommitStatus(name: "Deploy") {
                                sh 'skaffold deploy'
                            }

                            sh """curl -X POST $env.NOTIFY_URL -d '{"tag":"text","text":{"content":"\\nrollout controller deployed","mentioned_email_list":$env.NOTIFY_EMAILS,"at_all":false}}'"""
                        }
                    } catch (e) {
                        sh """curl -X POST $env.NOTIFY_URL -d '{"tag":"text","text":{"content":"\\nrollout controller deployed failed","mentioned_email_list":$env.NOTIFY_EMAILS,"at_all":false}}'"""
                    }


                }
            }
        }
    }
}
