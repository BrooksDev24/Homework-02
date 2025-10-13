pipeline{
    agent any

    environment
    {
        DOCKERHUB_CREDENTIALS = 'cweb-2140-01'

        //change this
        IMAGE_NAME = 'schbros/researchanddev2:latest'
    }

    stages
    {
        stage('Cloning Git')
        {
            steps
            {
                checkout scm
            }
        }



        stage('BUILD-AND-TAG')
        {
            agent {label 'CWEB-2040-01-app-server'}
            steps
            {
                script
                {
                    echo "Building Docker image ${IMAGE_NAME}"
                    app = Docker.build("${IMAGE_NAME}")                  
                        app.tag("latest")
                    
                }
            }
        }

        stage('POST-TO-DOCKERHUB')
        {
            agent {label 'CWEB-2040-01-app-server'}
            steps
            {
                script
                {
                    echo "pushing image ${IMAGE_NAME}:latest to Docker Hub..."
                    docker.withRegistry('https://registry.hub.docker.com', "${DOCKERHUB_CREDENTIALS}")
                    {
                        app.push("latest")
                    }
                }
            }
        }

        stage('DEPLOYMENT')
        {
            agent {label 'CWEB-2040-01-app-server'}
            steps
            {
                echo "Starting deployment using this docker-compose..."
                    script
                    {
                        dir("${WORKSPACE}")
                        {
                            sh'''
                            docker-compose down
                            docker-compose up -d
                            docker ps

                            '''
                        }

                    }
                echo "Deployment completed successfully!"
            }
        }
        
    }

}