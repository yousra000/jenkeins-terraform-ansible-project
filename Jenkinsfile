pipeline {
    agent {
        label 'jenkins-slave'  // Change to your Jenkins agent label
    }
    

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION    = 'us-east-1'  // Change to your region
        DOCKER_IMAGE_TAG     = 'latest'
        DB_PASSWORD        = credentials('DB_PASSWORD')  // Assuming you have a Jenkins credential for DB password
        DB_USERNAME       = credentials('DB_USERNAME')  // Assuming you have a Jenkins credential for DB password
    }

    options {
        skipDefaultCheckout(false)  // enable automatic SCM checkout
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }


    stages {
        
        // stage 1 : setup ssh key in jenkins slave
        stage('Setup SSH Key') {
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'ansible-ssh-key',  // Jenkins credential ID
                    keyFileVariable: 'SSH_KEY_FILE'
                )]) {
                    script {
                        // Make key readable only by current user
                        sh """
                            mkdir -p ~/.ssh
                            cp ${SSH_KEY_FILE} ~/.ssh/key1.pem
                            chmod 400 ~/.ssh/key1.pem
                        """
                    }
                }
            }
        }

        // STAGE 2: Terraform (init & apply)
        stage('Terraform Apply') {
            steps {
                dir('terraform') {  // Changes directory to terraform/
                    script {
                        sh 'terraform init'
                        sh 'terraform apply -var-file vars.tfvars -var "db_password=${DB_PASSWORD}" -var "db_username=${DB_USERNAME}" -auto-approve'
                    }
                }
            }
}

        // STAGE 3: Get terraform output and set environment variables
        stage('Get terraform output') {
            steps {
                dir('terraform') {  // Changes directory to terraform/
                script {
                    // Fetch ECR registry URL from Terraform output
                    REGISTRY = sh(
                        script: 'terraform  output -raw aws_ecr_repository | cut -d "/" -f1',
                        returnStdout: true
                    ).trim()
                    
                    // Fetch ECR repository name from Terraform output
                    REPOSITORY = sh(
                        script: 'terraform  output -raw aws_ecr_repository | cut -d "/" -f2',
                        returnStdout: true
                    ).trim()

                    // Fetch Redis from Terraform output
                    REDIS_HOSTNAME = sh(
                        script: 'terraform  output -raw redis_endpoint',
                        returnStdout: true
                    ).trim()

                    // Fetch RDS from Terraform output
                    RDS_HOSTNAME = sh(
                        script: 'terraform  output -raw mysql_endpoint | cut -d ":" -f1',
                        returnStdout: true
                    ).trim()

                    // Fetch Node App IP from Terraform output
                    NODE_APP_IP = sh(
                        script: 'terraform output -raw nodeapp',
                        returnStdout: true
                    ).trim()

                    
                    // Set environment variables
                    env.REDIS_HOSTNAME = REDIS_HOSTNAME
                    env.RDS_HOSTNAME = RDS_HOSTNAME
                    env.NODE_APP_IP = NODE_APP_IP
                    env.REPOSITORY = REPOSITORY
                    env.REGISTRY = REGISTRY
                }
            }
        }
        }

        // STAGE 4: Login to ECR, Build & Push Docker Image
        stage('Build and Push Docker Image') {
            steps {
                dir('nodeapp') {  // Changes directory to terraform/
                script {
                    // Login to AWS ECR
                    sh  "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | sudo docker login --username AWS --password-stdin ${env.REGISTRY}"

                    // Build Docker image
                    sh "sudo docker build -t ${env.REGISTRY}/${env.REPOSITORY}:${DOCKER_IMAGE_TAG} ."

                    // Push to ECR
                    sh "sudo docker push ${env.REGISTRY}/${env.REPOSITORY}:${DOCKER_IMAGE_TAG}"
                }
            }
        }
        }

        // STAGE 5: Prepare Ansible Inventory
        stage('Prepare Inventory') {
            steps {
                dir('ansible/node_app') {
                    script {
                        def inventoryContent = """[ubuntu_servers]
server1 ansible_host=${env.NODE_APP_IP} ansible_user=ubuntu"""

                        writeFile(
                            file: 'hosts.ini',
                            text: inventoryContent.trim()
                        )
                    }
                }
            }
        }

        // STAGE 6: Run Ansible Playbook on Application Node
        stage('Deploy with Ansible') {
            steps {
                dir('ansible/node_app') {  // Changes directory to terraform/
                script {
                    // Run Ansible playbook
                    sh "ansible-playbook -i hosts.ini  ansible.yml --extra-vars 'REGISTRY=${env.REGISTRY} REPOSITORY=${env.REPOSITORY} RDS_USERNAME=${DB_USERNAME} RDS_PASSWORD=${DB_PASSWORD} REDIS_HOSTNAME=${env.REDIS_HOSTNAME} RDS_HOSTNAME=${env.RDS_HOSTNAME}' "
                }
            }
        }
    }

    // STAGE 7: print load balancer DNS
    stage('print load balancer DNS') {
            steps {
                dir('terraform') {  // Changes directory to terraform/
                script {
                    LB_DNS = sh(
                        script: 'terraform output -raw lb_url',
                        returnStdout: true
                    ).trim()
                    echo "Load Balancer DNS: ${LB_DNS}"

                }
            }
        }
        }
    }


}
