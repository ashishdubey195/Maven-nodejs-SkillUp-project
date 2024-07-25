pipeline {
    agent any
    tools {
        maven 'mymaven'
    }
    environment {
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-id'
    }
    stages { 
        stage('Clone Repository') {
            agent { label 'dev-node'}
            steps {
                git credentialsId: 'github-token', url: 'https://github.com/ashishdubey195/Maven-nodejs-SkillUp-project.git', branch: 'master'
            } 
        }
            stage('Execute Ansible Playbook') {
            agent { label 'dev-node || int-node || prod-node' }
            steps {
                sh 'ansible-playbook installmaven-nodejsplaybook.yaml -i /opt/hosts'
                sh 'ansible-playbook docker-playbook.yaml -i /opt/hosts'
            }
        }
        stage('Build Java Code') {
            agent { label 'dev-node'}
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
            agent {label 'dev-node || int-node || prod-node'}
            steps {
                sh 'docker build -t my-node-app:1.0 .'
            }
        }
        stage('Run Container') {
            agent {label 'dev-node'}
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
            agent { label 'dev-node'}
            steps {
                script {
                    def dir = '/home/jenkins/workspace/skillup-project/addressbook_main'
                    sh "mkdir -p ${dir}"
                    sh "chmod 777 ${dir}"
                }
            }
        }
        stage('Build Image for addressbook') {
            agent {label 'dev-node'}
            steps {
                dir('/home/jenkins/workspace/skillup-project/addressbook_main/') {
                    sh 'docker build -t myaddressbook-app .'
                }
            }
        }
        stage('Build Container for addressbook image') {
            agent {label 'dev-node'}
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
            agent { label 'dev-node'}
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerhub-id', url: 'https://index.docker.io/v1/') {
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
