pipeline {
    agent any
    tools {
        maven 'mymaven'
    }
    environment {
        AZURE_CLIENT_ID = credentials('azure-client-id')
        AZURE_CLIENT_SECRET = credentials('azure-client-secret')
        AZURE_TENANT_ID = credentials('AZURE-TENNANT-ID')
        AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    }
    stages {
        stage('Clone Repository') {
            agent { label 'dev-node || int-node || prod-node' }
            steps {
                git credentialsId: 'github-token', url: 'https://github.com/ashishdubey195/Maven-nodejs-SkillUp-project.git', branch: 'master'
            }
        }
        stage('Install Terraform') {
            agent { label 'dev-node || int-node || prod-node' }
            steps {
                sh ''' 
                sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
                curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
                sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
                sudo apt-get update && sudo apt-get install terraform
                '''
            }
        }
        stage('Execute Terraform Script') {
            agent { label 'dev-node|| int-node || prod-node' }
            steps {
                dir('/home/jenkins/workspace/skillup-project/TERRAFORM-SCRIPTS') {
                    script {
                        withCredentials([
                            string(credentialsId: 'azure-client-id', variable: 'ARM_CLIENT_ID'),
                            string(credentialsId: 'azure-client-secret', variable: 'ARM_CLIENT_SECRET'),
                            string(credentialsId: 'AZURE-TENNANT-ID', variable: 'ARM_TENANT_ID'),
                            string(credentialsId: 'AZURE_SUBSCRIPTION_ID', variable: 'ARM_SUBSCRIPTION_ID')
                        ]) {
                            sh 'terraform init'
                            def environments = ['dev', 'int', 'prod']
                            for (environ in environments) {
                                stage("Provisioning ${environ} environment") {
                                    script {
                                        def workspaceExists = sh(script: "terraform workspace list | grep -w ${environ} || true", returnStdout: true).trim()
                                        if (workspaceExists == "") {
                                            sh "terraform workspace new ${environ}"
                                        } else {
                                            sh "terraform workspace select ${environ}"
                                        }
                                        sh "terraform apply -var-file=${environ}.tfvars -auto-approve"
                                        def vmPublicIp = sh(script: 'terraform output -raw public_ip_address', returnStdout: true).trim()
                                        echo "Public IP: ${vmPublicIp}"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        stage('Execute Ansible Playbooks') {
            agent { label 'dev-node || int-node || prod-node' }
            steps {
                dir('/home/jenkins/workspace/skillup-project') {
                    sh 'ansible-playbook installmaven-nodejsplaybook.yaml -i /etc/ansible/hosts'
                    sh 'ansible-playbook installdockerplaybook.yaml -i /etc/ansible/hosts'
                }
            }
        }
        stage('Build Java Code') {
            agent { label 'dev-node || int-node || prod-node' }
            steps {
                sh 'mvn -f addressbook_main/pom.xml clean install package'
            }
        }
        stage('Build Node.js Code') {
            agent { label 'dev-node || int-node || prod-node' }
            steps {
                sh 'npm install'
                sh 'npm test'
                sh 'npm run build'
            }
        }
        stage('Build Image') {
            agent { label 'dev-node || int-node || prod-node' }
            steps {
                sh 'docker build -t my-node-app:1.0 .'
            }
        }
        stage('Run Container') {
            agent { label 'dev-node || int-node || prod-node' }
            steps {
                script {
                    sh '''
                    docker stop my-node-app-container || true
                    docker rm my-node-app-container || true
                    '''
                    sh 'docker run -d -P --name my-node-app-container my-node-app:1.0'
                }
            }
        }
        stage('Setup') {
            agent  { label 'dev-node || int-node || prod-node' }
            steps {
                script {
                    def dir = '/home/jenkins/workspace/skillup-project/addressbook_main'
                    sh "mkdir -p ${dir}"
                    sh "chmod 777 ${dir}"
                }
            }
        }
        stage('Build Image for addressbook') {
            agent { label 'dev-node || int-node || prod-node' }
            steps {
                dir('/home/jenkins/workspace/skillup-project/addressbook_main') {
                    sh 'docker build -t myaddressbook-app .'
                }
            }
        }
        stage('Run Container for addressbook') {
            agent {label 'dev-node || int-node || prod-node'}
            steps {
                script {
                    sh '''
                    docker stop myaddressbook-container || true
                    docker rm myaddressbook-container || true
                    '''
                    sh 'docker run -d --name myaddressbook-container -P myaddressbook-app'
                }
            }
        }
        stage('Push Images to DockerHub') {
            agent { label 'dev-node || int-node || prod-node'}
            steps {
                script {
                    withDockerRegistry(credentialsId: "${DOCKERHUB_CREDENTIALS_ID}", url: 'https://index.docker.io/v1/') {
                        sh 'docker tag my-node-app:1.0 ashishdubey195/my-node-app:1.0'
                        sh 'docker push ashishdubey195/my-node-app:1.0'
                        sh 'docker tag myaddressbook-app ashishdubey195/myaddressbook-app:latest'
                        sh 'docker push ashishdubey195/myaddressbook-app:latest'
                    }
                }
            }
        }
    }
}
