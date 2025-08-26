pipeline {
    agent any

    stages {
        stage("Clone repo") {
            steps {
                git url: 'https://github.com/ByJeanCa/AtlasFlow', credentialsId: 'git-cred', branch: 'main'
            }
        }
        stage("Push docker image") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-cred', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASSWD' )]) {
                    sh '''
                        echo "$DH_PASSWD"| docker login -u "$DH_USER" --password-stdin
                        docker build -t "$DH_USER/nginx-web:${BUILD_NUMBER}" cont-app/
                        docker push "$DH_USER/nginx-web:${BUILD_NUMBER}"
                    '''
                }
            }

        }
    }
}