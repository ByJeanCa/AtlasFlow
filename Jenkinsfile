pipeline {
    agent any

    stages {
        stage("Clone repo") {
            steps {
                git url: 'https://github.com/ByJeanCa/AtlasFlow', credentialsId: 'git-cred', branch: 'main'
            }
        }
        stage("Infrastructure provision") {
            agent { 
                docker { 
                    image 'hashicorp/terraform:1.6.6' 
                    args "--entrypoint='' -i -u root:root" 
                    reuseNode true 
                    } 
                }
            steps {
                withCredentials([
                    file(credentialsId: 'atlasflow-tfvars', variable: 'TFVARS'),
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-cred']
                    ]) {
                    dir ('infrastructure'){
                        sh '''
                        cp "$TFVARS" terraform.tfvars
                        terraform init -input=false
                        terraform apply -auto-approve -input=false
                        '''
                    }
                }
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