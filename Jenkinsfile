pipeline {
    agent any

    stages {
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
                        apk add --no-cache curl ca-certificates bind-tools
                        update-ca-certificates || true
                        
                        public_ip=$(curl -4 -fsS https://api.ipify.org)
                        cp "$TFVARS" terraform.tfvars
                        echo "\nmy_ip = [\\"${public_ip}/32\\"]" >> terraform.tfvars

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
        stage("Deploy") {
            agent {
                docker {
                    image 'willhallonline/ansible'
                    args '-u root:root'
                    reuseNode true
                }
            }
            steps {
                withCredentials([
                    file(credentialsId: 'test-ssh', variable: 'SSH_KEY'),
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-cred']
                    ]) {
                    dir('ansible') {
                        sh '''
                        set -e
                        ansible-galaxy collection install -r requirements.yml --force
                        python3 -c "import boto3, botocore" || pip3 install --no-cache-dir boto3 botocore
                        
                        ansible-playbook -i inventory/aws_ec2.yml deploy.yml \
                        --private-key "$SSH_KEY" \
                        --extra-vars "image_tag=${BUILD_NUMBER}"
                        '''
                    }
                }
            }
        }
    }
}