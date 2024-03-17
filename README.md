# rhda-pipelines-examples
Bring some examples of how to use [RHDA Jenkins plugin](https://plugins.jenkins.io/redhat-dependency-analytics/)


## Prerequisites
1. Download Jenkins LTS and deploy it on your machine
```shell
curl -X GET https://get.jenkins.io/war-stable/2.426.3/jenkins.war -o /tmp/jenkins.war
# run jenkins on http://localhost:8080
java -jar /tmp/jenkins.war --enable-future-java
```

2. Podman CLI Or Docker Daemon, if you don't have docker, can spin up a docker daemon inside a podman container( DIND -Docker in Docker)
   , And Map your user $HOME/.jenkins directory as volume to the container  
```shell
podman volume create some-docker-certs-ca
podman volume create some-docker-certs-client
podman network create docker-network
podman run --privileged --user=root --name docker -d --network docker-network -e DOCKER_TLS_CERTDIR=/certs -v some-docker-certs-ca:/certs/ca -v some-docker-certs-client:/certs/client -v $HOME/.jenkins/:$HOME/.jenkins -p 2376:2376 docker:dind
```
3. Install Redhat Dependency Analytics Jenkins Plugin on your jenkins deployed instance - [Instructions](https://github.com/jenkinsci/redhat-dependency-analytics-plugin?tab=readme-ov-file#1-install-the-redhat-dependency-analytics-jenkins-plugin)
## Demos

### Basic generic Pipeline
__Note: This pipeline assumes that package managers binaries installed in the jenkins master/agent, and that manifest file pre installed ( needed for python)__

```java
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                // Checkout the Git repository
                checkout([$class: 'GitSCM', branches: [[name: 'main']], userRemoteConfigs: [[url: '[https://github.com/Your github project link.git']]](https://github.com/Your github project link.git)])
            }
        }
        stage('RHDA Step') {
            steps {
                echo 'RHDA'
                rhdaAnalysis consentTelemetry: true, file: '/path/to/manifest/in/workspace'
            }
        }
    }
}

```

### Python Pip 

#### Configuration
 - Need to install [Docker pipeline plugin](https://plugins.jenkins.io/docker-workflow/)
 - Need to install [Build With Parameters Plugin](https://plugins.jenkins.io/build-with-parameters/)

#### Pipeline Using Environment Variables
```java
node {
    def jdk
    def dockerArguments= '--user=root'
    def pipFreezeOutput
    def pipShowOutput
    def pythonImage = "python:${params.PYTHON_VERSION}-slim"
    def gitRepoWithRequirements = "${params.REQUIREMENTS_GIT_REPO}"
    def gitRepoWithRequirementsBranch = "${params.REQUIREMENTS_GIT_BRANCH}"
    final VULNERABLE_RETURN_CODE = "2"


    stage('Checkout Git Repo') { // for display purposes
        // Get some code from a GitHub repository
        dir('requirementsDir') {
            git  branch: gitRepoWithRequirementsBranch, url: gitRepoWithRequirements
        }

    }

    stage('Install Python Package') {
        docker.withTool('docker-tool') {
            docker.withServer('tcp://localhost:2376','docker-server-certs'){

                docker.image(pythonImage).inside(dockerArguments) {
                    sh 'pip install -r requirementsDir/requirements.txt'
                    pipFreezeOutput = sh(script: "pip freeze --all" ,returnStdout: true ).trim()
                    writeFile([file: 'pip-freeze.txt', text: pipFreezeOutput])
                    pipFreezeOutput = sh(script: "pip freeze --all | awk -F \"==\" '{print \$1}' | tr \"\n\" \" \"" ,returnStdout: true ).trim()
                    pipShowOutput = sh(script:"pip show ${pipFreezeOutput}" ,returnStdout: true )
                    writeFile([file: 'pip-show.txt', text: pipShowOutput])


                }
            }
        }
    }
    stage('RHDA Run Analysis') {
        def pipFreezeB64= sh(script: 'cat pip-freeze.txt | base64 -w0' ,returnStdout: true ).trim()
        def pipShowB64= sh(script: 'cat pip-show.txt | base64 -w0',returnStdout: true ).trim()
        echo "pipFreezeB64= ${pipFreezeB64}"
        echo "pipShowpipShowB64= ${pipShowB64}"
        withEnv(["EXHORT_PIP_FREEZE=${pipFreezeB64}","EXHORT_PIP_SHOW=${pipShowB64}"]) {

            def result = rhdaAnalysis consentTelemetry: true, file: "${WORKSPACE}/requirementsDir/requirements.txt"
            if(result.trim().equals(VULNERABLE_RETURN_CODE) ) {
                unstable(message: "There are some vulnerabilities in Manifest, please upgrade according to the report")
            }
        }

    }

    stage('Clean Workspace') {
        cleanWs cleanWhenAborted: false, cleanWhenFailure: false, cleanWhenNotBuilt: false, cleanWhenUnstable: false
    }

}

```

#### Pipeline Using Pretender Script ( Scripted Pipeline)

```java
node {
    def jdk
    def dockerArguments= '--user=root'
    def pipFreezeOutput
    def pipShowOutput
    def pythonImage = "python:${params.PYTHON_VERSION}-slim"
    def gitRepoWithRequirements = "${params.REQUIREMENTS_GIT_REPO}"
    def gitRepoWithRequirementsBranch = "${params.REQUIREMENTS_GIT_BRANCH}"
    final VULNERABLE_RETURN_CODE = "2"

    stage('Fetch Pretender pip script') { // for display purposes
        // Get some code from a GitHub repository
        dir('core') {
            git  branch: 'main', url:'https://github.com/zvigrinberg/rhda-pipelines-examples.git'
        }
    }

    stage('Checkout Git Repo') { // for display purposes
        // Get some code from a GitHub repository
        dir('requirementsDir') {
            git  branch: gitRepoWithRequirementsBranch, url: gitRepoWithRequirements
        }



    }

    stage('Install Python Package') {
        docker.withTool('docker-tool') {
            docker.withServer('tcp://localhost:2376','docker-server-certs'){

                docker.image(pythonImage).inside(dockerArguments) {
                    sh 'pip install -r requirementsDir/requirements.txt'
                    pipFreezeOutput = sh(script: "pip freeze --all" ,returnStdout: true ).trim()
                    writeFile([file: 'pip-freeze.txt', text: pipFreezeOutput])
                    pipFreezeOutput = sh(script: "pip freeze --all | awk -F \"==\" '{print \$1}' | tr \"\n\" \" \"" ,returnStdout: true ).trim()
                    pipShowOutput = sh(script:"pip show ${pipFreezeOutput}" ,returnStdout: true )
                    writeFile([file: 'pip-show.txt', text: pipShowOutput])


                }
            }
        }
    }
    stage('RHDA Run Analysis') {
        echo "pipFreezeOutput= ${pipFreezeOutput}"
        echo "pipShowOutput= ${pipShowOutput}"
        def rhdaWorkspace = env.WORKSPACE
        escapedWorkspace = rhdaWorkspace.toString().replaceAll(" ", "\\\\ ")
        echo "escapedWorkspace= ${escapedWorkspace}"
        def doubleEscapedWorkspace = escapedWorkspace.replaceAll("\\\\","\\\\\\\\").replaceAll("\\/","\\\\/")
        echo "doubleEscapedWorkspace= ${doubleEscapedWorkspace}"
// sh(script: "echo ${escapedWorkspace} | sed 's/\\/\\\\/g' | sed 's/\//\\\//g'" ,returnStdout: true ).trim()
        sh "sed 's/\$PLACE_HOLDER/${doubleEscapedWorkspace}/g' core/python-pip/using-mock-script/pythonMock.sh > /tmp/pip ; chmod +x /tmp/pip"
        echo "escapedWorkspace= ${escapedWorkspace}"
        withEnv(["WORKSPACE_PATH=${escapedWorkspace}","EXHORT_PIP3_PATH=/tmp/pip","EXHORT_PYTHON3_PATH=/tmp/pip"]) {

            def result = rhdaAnalysis consentTelemetry: true, file: "${WORKSPACE}/requirementsDir/requirements.txt"
            if(result.trim().equals(VULNERABLE_RETURN_CODE) ) {
                unstable(message: "There are some vulnerabilities in Manifest, please upgrade according to the report")
            }
        }

    }

    stage('Clean Workspace') {
        cleanWs cleanWhenAborted: false, cleanWhenFailure: false, cleanWhenNotBuilt: false, cleanWhenUnstable: false
    }

}

```
#### Pretender script definition( Scripted Pipeline)
```shell
ARGUMENT=$1
case $ARGUMENT in
  --version)
    echo "3.x"
    exit 0
    ;;
  show)
    eval "cat $PLACE_HOLDER/pip-show.txt"
    exit 0
    ;;
  freeze)
    eval "cat $PLACE_HOLDER/pip-freeze.txt"
    exit 0
    ;;
esac
exit 23

```

#### Podman
If you don't want to use docker pipeline plugin, because you don't have docker engine installed or don't want to use `dind` As explained above, you can instead use directly podman in the pipeline:
In the above two pipelines, you can just replace stage `Install Python Package` implementation with the following one:  
##### Prerequisite
 - Podman pre-installed and exists on path of your computer or on the running agent/slave.
```java
stage('Install Python Package') {
    try{
        sh "podman run -d --name python-run -v requirements.txt:/tmp/requirements.txt ${pythonImage} sleep infinity"
        sh 'podman exec python-run -- pip install -r /tmp/requirements.txt'
        
        pipFreezeOutput=sh(script:"podman exec python-run -- pip freeze --all",returnStdout:true).trim()
        writeFile([file:'pip-freeze.txt',text:pipFreezeOutput])
        pipFreezeOutput=sh(script:"podman exec python-run -- pip freeze --all | awk -F \"==\" '{print \$1}' | tr \"\n\" \" \"",returnStdout:true).trim()
        pipShowOutput=sh(script:"podman exec python-run -- pip show ${pipFreezeOutput}",returnStdout:true)
        writeFile([file:'pip-show.txt',text:pipShowOutput])
        sh 'podman stop python-run'
        sh 'podman rm python-run'
        }
    catch(Exception e)
        {
            error(message: "error encountered --> ${e}")
        }
 }
```

### Java Maven + NodeJS NPM + Golang Go Modules

 - For all these 3 package managers we will use jenkins tools that will be injected to pipeline
#### Configuration
 - Need to install [Build With Parameters Plugin](https://plugins.jenkins.io/build-with-parameters/)
 - Need to install [Go Jenkins Plugin ](https://plugins.jenkins.io/golang/) and define tool with the name that defined in the pipeline
 - Need to Install [NodeJS Jenkins Plugin ]([https://plugins.jenkins.io/golang/](https://plugins.jenkins.io/nodejs/)) and define tool with the name that defined in the pipeline
#### Pipeline Example ( Declarative Pipeline)
```java
pipeline {
    agent any
    parameters {
        choice(name: 'MANIFEST_TYPE', choices: ['maven', 'npm', 'golang'], description: 'manifest type to run analysis on')
        string(name: 'MANIFEST_GIT_BRANCH', defaultValue: "main", description: 'git repository of manifest branch')
        string(name: 'MANIFEST_GIT_REPO', defaultValue: "https://github.com/zvigrinberg/rhda-pipelines-examples.git", description: 'git repository of manifest')
        string(name: 'MANIFEST_DIR', defaultValue: "", description: 'git repository of manifest')
    }
    environment {
        EXHORT_DEBUG =  "true"
    }
    stages {
        stage('checkout manifest Repository') {
            steps {
                git branch: MANIFEST_GIT_BRANCH, url: MANIFEST_GIT_REPO
            }
        }

        stage('RHDA Analysis - Maven') {
            when {
                expression { params.MANIFEST_TYPE == 'maven' }
            }
            steps {
                script {
                    def maven = tool 'apache-maven'
                    env.EXHORT_MVN_PATH = "$maven/bin/mvn"
                    invokeRhdaAnalysis("pom.xml",MANIFEST_DIR)
                }
            }
        }
        stage('RHDA Analysis - Npm') {
            when {
                expression { params.MANIFEST_TYPE == 'npm' }
            }
            steps {
                script {
                    def node = tool 'node-lts'
                    env.EXHORT_NPM_PATH = "$node/bin/npm"
                    echo "node=$node"
                    sh 'echo "exhort npm path = ${EXHORT_NPM_PATH}"'
                    invokeRhdaAnalysis("package.json",MANIFEST_DIR)
                }
            }
        }

        stage('RHDA Analysis - go') {
            when {
                expression { params.MANIFEST_TYPE == 'golang' }
            }
            steps {
                script {
                    def go = tool 'golang'
                    env.EXHORT_GO_PATH = "$go/bin/go"
                    invokeRhdaAnalysis("go.mod",MANIFEST_DIR)
                }
            }
        }

        stage('Clean Workspace') {
            steps {
                cleanWs cleanWhenAborted: false, cleanWhenFailure: false, cleanWhenNotBuilt: false, cleanWhenUnstable: false
            }
        }


    }
}

private String getPathOfBinary(String packageManifest) {
    return sh(returnStdout: true, script: "which ${packageManifest}")
}

private void invokeRhdaAnalysis(String manifestName,String pathToManifestDir) {
    final VULNERABLE_RETURN_CODE = "2"
    final GENERAL_ERROR_RETURN_CODE = "1"
    def theFile
    if(pathToManifestDir.trim().equals("")) {
        theFile = "${WORKSPACE}/${manifestName}"
    }
    else {
        theFile = "${WORKSPACE}/${pathToManifestDir}/${manifestName}"
        echo "theFile=${theFile}"
    }
    try {
        def result
        withEnv(['EXHORT_DEBUG=true']) {
            result = rhdaAnalysis consentTelemetry: true, file: theFile
        }
        if (result.trim().equals(VULNERABLE_RETURN_CODE)) {
            unstable(message: "There are some vulnerabilities in Manifest, please upgrade according to the report")
        }
        else {
            if(result.trim().equals(GENERAL_ERROR_RETURN_CODE)) {
                error(message: "Failed To Invoke RHDA Analysis")
            }
        }
    }
    catch (Exception e) {
        error(message: "Intercepted Error --> ${e}")
    }
}
```



