pipeline {
   agent any
   stages{
       stage('checkout'){
           steps{
               git branch:'master', url:"https://github.com/gary918/terraform.git"
           }
       }
        stage('set terraform path'){
            steps{
               script{
                   tfHome = tool name: 'Terraform'
                   env.PATH = "${tfHome}:${env.PATH}"
               }
               sh 'terraform -version'
           }
       }
        stage('Provision'){
            steps{
                sh 'terraform init'
                sh 'terraform plan -out=plan'
                sh 'terraform apply plan'
            }
        }
    }
}