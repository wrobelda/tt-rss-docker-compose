pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }

    triggers { pollSCM 'H/30 * * * *' }

    environment {
        registryCredential = 'cthulhoo_docker_hub'
        localRegistryCredential = 'jenkins_registry_fakecake'

        deploy_key = "srv.tt-rss.org"
        deploy_host = "tt-rss.fakecake.org"
    }

    stages {
        stage('checkout') {
            steps {
                dir('tt-rss') {
                    git url: 'https://dev.tt-rss.org/tt-rss/tt-rss.git'
                }
            }
        }
        stage('phpunit') {
            steps {
                sh """
                docker run --rm \
                    --workdir /app \
                    -v ${env.WORKSPACE}/tt-rss:/app \
                    registry.fakecake.org/php:8.1-cli \
                    php ./vendor/bin/phpunit
                """
            }
        }
        stage('phpstan') {
            steps {
                sh """
                docker run --rm \
                    --workdir /app \
                    -v ${env.WORKSPACE}/tt-rss:/app \
                    registry.fakecake.org/php:8.1-cli \
                    php -d memory_limit=-1 ./vendor/bin/phpstan --memory-limit=2G
                """
            }
        }
        stage('build') {
            when {
                branch "static-dockerhub"
            }
            environment {
                REPO_TIMESTAMP = sh(returnStdout: true,
                    script: "git --git-dir 'tt-rss/.git' --no-pager log --pretty='%ct' -n1 HEAD")
                        .trim()

                REPO_COMMIT = sh(returnStdout: true,
                    script: "git --git-dir 'tt-rss/.git' --no-pager log --pretty='%h' -n1 HEAD")
                        .trim()

                REPO_COMMIT_FULL = sh(returnStdout: true,
                    script: "git --git-dir 'tt-rss/.git' --no-pager log --pretty='%H' -n1 HEAD")
                        .trim()

                BUILD_TAG = sh(returnStdout: true,
                    script: "echo \$(date -d @${REPO_TIMESTAMP} +%y.%m)-${REPO_COMMIT}")
                        .trim()
            }
            steps {
                dir('src') {
                    echo "Building for tag: ${env.BUILD_TAG}, commit: ${env.REPO_COMMIT_FULL}"

                    dir('app') {
                        script {
                            def image = docker.build(
                                "cthulhoo/ttrss-fpm-pgsql-static:${env.BUILD_TAG}",
                                "--build-arg ORIGIN_REPO_MAIN=https://dev.tt-rss.org/tt-rss/tt-rss.git "+
                                "--build-arg ORIGIN_REPO_XACCEL=https://dev.tt-rss.org/tt-rss/ttrss-nginx-xaccel.git " +
                                "--build-arg ORIGIN_COMMIT=${env.REPO_COMMIT_FULL} "+
                                "-f Dockerfile .")

                            docker.withRegistry('', registryCredential) {
                                image.push("${env.BUILD_TAG}")
                                image.push("latest")
                            }

                            docker.withRegistry('https://registry-rw.fakecake.org', localRegistryCredential) {
                                image.push("${env.BUILD_TAG}")
                                image.push("latest")
                            }
                        }
                    }

                    dir('web-nginx') {
                        script {
                            def image = docker.build("cthulhoo/ttrss-web-nginx:${env.BUILD_TAG}", "-f Dockerfile .")

                            docker.withRegistry('', registryCredential) {
                                image.push("${env.BUILD_TAG}")
                                image.push("latest")
                            }

                            docker.withRegistry('https://registry-rw.fakecake.org', localRegistryCredential) {
                                image.push("${env.BUILD_TAG}")
                                image.push("latest")
                            }
                        }
                    }
                }
            }
        }
        stage('phpdoc') {
            when {
                branch "static-dockerhub"
            }
            steps {
                sh """
                    docker run --rm \
                        --workdir /app \
                        -v ${env.WORKSPACE}/tt-rss:/app \
                        registry.fakecake.org/phpdoc/phpdoc:3 \
                        -d /app/tt-rss/classes \
                        -d /app/tt-rss/include \
                        -t /app/phpdoc/out \
                        --cache-folder=/app/phpdoc/cache \
                        --visibility="public"
                """

                sshagent(credentials: ["${deploy_key}"]) {
                    script {
                        sh """
                            rsync -e 'ssh -o StrictHostKeyChecking=no' \
                            -aP ${env.WORKSPACE}/tt-rss/phpdoc/out/ ${deploy_host}:phpdoc/
                        """
                    }
                }
            }
        }
    }

    post {
        failure {
             mail body: "Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER}<br> build URL: ${env.BUILD_URL}",
                charset: 'UTF-8', from: 'jenkins@fakecake.org',
                mimeType: 'text/html',
                subject: "Build failed: ${env.JOB_NAME}",
                to: "fox@fakecake.org";
         }
    }
}
