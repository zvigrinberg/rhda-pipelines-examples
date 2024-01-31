node {
    def jdk
    def dockerArguments= '--user=root'
    def pipFreezeOutput
    def pipShowOutput 
    stage('Preparations') { // for display purposes
        // Get some code from a GitHub repository
        git  branch: 'main', url:'https://github.com/zvigrinberg/rhda-pipelines-examples.git'
        sh 'mkdir -p /tmp/jenkins-test-pip ; cp requirements.txt /tmp/jenkins-test-pip/requirements.txt'
        // Get the Maven tool.
        // ** NOTE: This 'M3' Maven tool must be configured
        // **       in the global configuration.
        jdk = tool 'jdk11'
        

    }
    stage('Install Python pip package') {
          docker.withTool('docker-tool') {
             docker.withServer('tcp://localhost:2376','docker-server-certs'){
                 
               docker.image('python:3.12.1').inside(dockerArguments) {
                 sh 'pip install -r requirements.txt'
                 pipFreezeOutput = sh(script: "pip freeze --all | awk -F \"==\" '{print \$1}' | tr \"\n\" \" \"" ,returnStdout: true ).trim()
                 pipShowOutput = sh(script:"pip show ${pipFreezeOutput}" ,returnStdout: true )

                 
               }
            }
        }
    }
    stage('Run RHDA Analysis') {
        echo "pipFreezeOutput= ${pipFreezeOutput}"
        echo "pipShowOutput= ${pipShowOutput}"
        rhdaAnalysis consentTelemetry: true, file: 'requirements.txt'
    }
    
}
