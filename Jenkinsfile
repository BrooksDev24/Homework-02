pipeline{
    agent any

    environment
    {
        DOCKERHUB_CREDENTIALS = 'cweb-2140-01'

        //change this to your dockerhub
        IMAGE_NAME = 'schbros/chatappsonarpipe'

  

        // trivy
        TRIVY_SEVERITY = "HIGH,CRITICAL"

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


 stage("Check Docker Availability") {
            steps {
                script {
                    echo ' Checking Docker installation...'
                    def dockerCheck = sh(script: 'which docker', returnStatus: true)
                    if (dockerCheck != 0) {
                        error " Docker command not found! Please install Docker or mount /var/run/docker.sock."
                    }
                    sh 'docker --version'
                }
            }
        }
 
        stage("Pull Target Container Image") {
            steps {
                script {
                    echo "⬇️ Pulling image: ${IMAGE_NAME}"
                    sh "docker pull ${IMAGE_NAME}"
                }
            }
        }
 
 
        stage("Container Vulnerability Scan (Trivy)") {
            steps {
                script {
                    catchError (buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    echo " Scanning Docker image ${IMAGE_NAME} for vulnerabilities..."
 
                    // JSON report
                    sh """
                        docker run --rm -v \$(pwd):/workspace aquasec/trivy:latest image \
                        --exit-code 0 \
                        --format json \
                        --output /workspace/trivy-report.json \
                        --severity ${TRIVY_SEVERITY} \
                        ${IMAGE_NAME}
                    """
 
                    // HTML report
                    sh """
                        docker run --rm -v \$(pwd):/workspace aquasec/trivy:latest image \
                        --exit-code 0 \
                        --format template \
                        --template "@/contrib/html.tpl" \
                        --output /workspace/trivy-report.html \
                        ${IMAGE_NAME}
                    """
                    }
                }
            }
            post {
                always {
                    echo "Archiving Trivy reports..."
                    archiveArtifacts artifacts: 'trivy-report.json,trivy-report.html', allowEmptyArchive: true
                }
            }
        }
 
        stage("Summarize Vulnerabilities") {
            steps {
                catchError (buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                script {
                    if (fileExists('trivy-report.json')) {
                        def reportContent = readFile('trivy-report.json')
                        def reportJson = new groovy.json.JsonSlurper().parseText(reportContent)
 
                        def highCount = 0
                        def criticalCount = 0
 
                        reportJson.Results.each { result ->
                            result.Vulnerabilities?.each { vuln ->
                                switch (vuln.Severity) {
                                    case 'HIGH': highCount++; break
                                    case 'CRITICAL': criticalCount++; break
                                }
                            }
                        }
 
                        echo "HIGH vulnerabilities: ${highCount}"
                        echo "CRITICAL vulnerabilities: ${criticalCount}"
 
                        if (criticalCount > 0) {
                            error "Critical vulnerabilities detected: ${criticalCount}"
                        }
                    } else {
                        echo "Trivy JSON report not found!"
                    }
                }
            }
        }
        }

       stage("DAST Scan with OWASP ZAP") {
            steps {
                script {
                    echo ' Running OWASP ZAP baseline scan...'
 
                    // Run ZAP baseline scan and capture exit code
                    def exitCode = sh(script: '''
                        docker run --rm --user root --network host -v $(pwd):/zap/wrk:rw \
                        -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
                        -t http://172.233.217.56 \
                        -r zap_report.html -J zap_report.json
                    ''', returnStatus: true)
 
                    echo "ZAP scan finished with exit code: ${exitCode}"
 
                    // Parse ZAP JSON report safely
                    if (fileExists('zap_report.json')) {
                        def zapContent = readFile('zap_report.json')
                        def zapJson = new groovy.json.JsonSlurper().parseText(zapContent)
 
                        def highCount = 0
                        def mediumCount = 0
                        def lowCount = 0
 
                        zapJson.site.each { site ->
                            site.alerts.each { alert ->
                                switch (alert.risk) {
                                    case 'High': highCount++; break
                                    case 'Medium': mediumCount++; break
                                    case 'Low': lowCount++; break
                                }
                            }
                        }
 
                        echo "High severity issues: ${highCount}"
                        echo "Medium severity issues: ${mediumCount}"
                        echo "Low severity issues: ${lowCount}"
                    } else {
                        echo "ZAP JSON report not found, continuing build..."
                    }
                }
            }
       }


        
       
 



          stage("SCA-SAST-SNYK-TEST")
         {
              agent any
              steps 
              {
                   script
                   {
                        snykSecurity(
                             snykInstallation:'snyk-installations',
                             snykTokenId:'Snyk-Token',
                             severity:'critical',
                             failOnIssues:false
                        )
                   }
              }
         }


           stage('SonarQube Analysis') {
            agent {
                label 'CWEB-2040-01-app-server'
            }
            steps {
                script {
                    def scannerHome = tool 'SonarQube-Scanner'
                    withSonarQubeEnv('SonarQube-Scanner') {
                        sh "${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=NodeJSChatapp \
                            -Dsonar.sources=."
                    }
                }
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
                    app = docker.build("${IMAGE_NAME}")
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
