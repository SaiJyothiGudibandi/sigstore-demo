// Credential ID:
// cosign-key (private key)
// cosign-pub (public key)

def build_metaData

node("jenkins-slave"){
    def envType = getEnvtype("${env.BRANCH_NAME}")
    echo("## At envType: ${envType}")

    def imageName = "us-central1-docker.pkg.dev/citric-nimbus-377218/docker-dev-local/sigstore-demo-image:1.0.0"

    // Chekout
	stage("Checkout"){
		def scmVars = checkout scmGit(branches: [[name: '*/feature-demo-3']], extensions: [], userRemoteConfigs: [[credentialsId: 'devops-team-92', url: 'https://github.com/SaiJyothiGudibandi/sigstore-demo.git']])
        echo "## At scmVars : ${scmVars}"
        echo "## At scmVars.GIT_COMMIT : ${scmVars.GIT_COMMIT}"
        def git_commit = getAuthorEmailForCommit() 
        echo "## At git_commit : ${git_commit}"
        def committed_by = getAuthorEmailForCommit("${scmVars.GIT_COMMIT}")
        echo "## At committed_by : ${committed_by}"
		build_metaData = ["environment" : "${envType}", "type": "checkout", "stage_properties": [ "jenkins": ["ci": [ "build_url": "${env.BUILD_URL}", "job_name": "${env.JOB_NAME}".replaceAll("\\s", "-"), "build_number": "${env.BUILD_ID}", "user": "${env.USER}"]], "scm": ["git_url": "${scmVars.GIT_URL}", "branch_name": "${env.BRANCH_NAME}", "committed_by": "${committed_by}"]]]
		createMetadataFile("Checkout", build_metaData)
	}

    // Code Build
	stage("Code Build"){
		docker.image('kartikjena33/cosign:latest').inside('-u 0:0 -v /root/.m2:/root/.m2'){
		    sh("mkdir -p cosign-metadatafiles")
            echo("----- BEGIN Code Build -----")
            sh 'mvn clean install'
            build_metaData = ["environment" : "${envType}", "type": "codebuild", "stage_properties": [ "running_on": "kartikjena33/cosign:latest", "stage_runner_image_status": "APPROVED", "command_executed": ["mvn clean install"]]]
            createMetadataFile("Code-Build", build_metaData)
            echo("----- COMPLETED Code Build -----")
        }
	}

    // Sonar Scan
	stage('Sonar Scan') {
		docker.image('kartikjena33/cosign:latest').inside('-u 0:0 '){
            echo("----- BEGIN Sonar Scan -----")
            echo("Sonar Scan is in progress")
            build_metaData = ["environment" : "${envType}", "type": "sonarquality", "stage_properties":[ "enabled": "true", "scan_results": "pass"]]
            createMetadataFile("Sonar-Scan", build_metaData)
            echo("----- COMPLETED Sonar Scan -----")
		}
    }

    //  Blackduck Scan 
    stage('BlackDuck Scan') {
        echo("----- BEGIN BlackDuck Scan-----")
        echo("BlackDuck Scan is in progress")
        build_metaData = ["environment" : "${envType}", "type": "blackduckquality", "stage_properties":[ "enabled": "true", "scan_results": "pass"]]
        createMetadataFile("BlackDuck-Scan", build_metaData)
        echo("----- COMPLETED BlackDuck Scan-----")
    }

    // Docker Build
	stage('Docker Build') {
        echo("----- BEGIN Docker Build -----")
        sh 'docker build -t us-central1-docker.pkg.dev/citric-nimbus-377218/docker-dev-local/sigstore-demo-image:1.0.0 .'
        build_metaData = ["environment" : "${envType}", "type": "dockerbuild", "stage_properties":[ "running_on": "jenkins_slave_2", "application_image": "APPROVED", "command_executed": "docker build -t us-central1-docker.pkg.dev/citric-nimbus-377218/docker-dev-local/sigstore-demo-image:1.0.0 ."]]
        createMetadataFile("Docker-Build", build_metaData)
        echo("----- COMPLETED Docker Build -----")
    }

    // Docker Publish
	stage('Docker Publish') {
	    echo("----- BEGIN Docker Publish-----")
	    withCredentials([usernamePassword(credentialsId: 'docker-login', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
            sh 'gcloud auth configure-docker us-central1-docker.pkg.dev --quiet'                      
            sh 'docker push us-central1-docker.pkg.dev/citric-nimbus-377218/docker-dev-local/sigstore-demo-image:1.0.0'
            build_metaData = ["environment" : "${envType}", "type": "dockerbuild", "stage_properties":["credentials": "docker-login", "url": "us-central1-docker.pkg.dev/citric-nimbus-377218/docker-dev-local/sigstore-demo-image:1.0.0", "checksum": "f5f92ef4e533ecffa18d058bee91cd818de3ba8145bfa63e19c0a7da31bca5df"]]
            createMetadataFile("Docker-Build", build_metaData)
            cosignClean(imageName)
            cosignAttest(imageName)
	    }
	    echo("----- COMPLETED Docker Publish-----")
    }

    // Helm Build
    stage('Helm Build') {
        docker.image('kartikjena33/cosign:latest').inside('-u 0:0 '){
            echo("----- BEGIN Helm Build -----")
            dir("mychart/"){
                sh("helm package --sign --key 'CI-Pipeline' .")
                sh("helm sigstore upload sigstore-demo-1.0.5.tgz")
            }
            build_metaData = ["environment" : "${envType}", "type": "helmbuild", "stage_properties":[ "running_on": "kartikjena33/cosign:latest", "stage_runner_image_status": "APPROVED", "command_executed": ["helm package --sign --key 'CI-Pipeline' .", "helm sigstore upload sigstore-demo-1.0.5.tgz"]]]
            createMetadataFile("Helm-Build", build_metaData)
            withCredentials([usernamePassword(credentialsId: 'docker-login', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                sh 'gcloud auth configure-docker us-central1-docker.pkg.dev --quiet'
                cosignAttestFile(imageName, "helm-build")
            }
            echo("----- COMPLETED Helm Build -----")
        }
	}

    // Helm Publish
    stage('Helm Publish') {
        docker.image('kartikjena33/cosign:latest').inside('-u 0:0 '){
            echo("----- BEGIN Helm Publish -----")
            dir("mychart/"){
                sh("gcloud auth configure-docker us-central1-docker.pkg.dev --quiet")
                sh("helm sigstore verify sigstore-demo-1.0.5.tgz")
                sh("helm push sigstore-demo-1.0.5.tgz oci://us-central1-docker.pkg.dev/citric-nimbus-377218/helm-dev-local")
            }
            build_metaData = ["environment" : "${envType}", "type": "helmpublish", "stage_properties":[ "credentials": "jfrog-artifact", "url": "oci://us-central1-docker.pkg.dev/citric-nimbus-377218/helm-dev-local/sigstore-demo-1.0.5.tgz", "checksum": "b3414aa09d1157af794ef65d699bf3b8d2a8bc784aaceb2ceb152d9918de5380"]]
            createMetadataFile("Helm-Publish", build_metaData)
            withCredentials([usernamePassword(credentialsId: 'docker-login', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                sh 'gcloud auth configure-docker us-central1-docker.pkg.dev --quiet'
                cosignAttestFile(imageName, "helm-publish")
            }
            echo("----- COMPLETED Helm Publish -----")
        }
	}

    // Cosign Verfication
	stage('Verfication') {
		docker.image('kartikjena33/cosign:latest').inside('-u 0:0 '){
            echo("----- BEGIN Verfication -----")
            dir("cosign-metadatafiles"){
		        def files = findFiles(glob: '*.json')
		        if ("${files.length}" >= 1) {
			        files.each { metaDatafile ->
			        cosignVerifyAttestation(imageName)
			    }
		    }
                    echo("----- COMPLETED Helm Publish -----")
        	}
        }
	}
}

def createMetadataFile(stageName, metaData) {
    stageName = stageName.replaceAll("[^a-zA-Z0-9-]+", "-").toLowerCase()
    writeJSON(file: "cosign-metadatafiles/${stageName}-MetaData.json", json: metaData, pretty: 4)
    cosignSignBlob(stageName)
    sh("ls -al cosign-metadatafiles/")
    sh("cat cosign-metadatafiles/${stageName}-MetaData.json")
}

def cosignSignBlob(metaDataFile){
    withCredentials([file(credentialsId: 'cosign-key', variable: 'cosign_pvt')]) {
        sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign sign-blob -y --key '${cosign_pvt}' 'cosign-metadatafiles/${metaDataFile}-MetaData.json' --output-signature 'cosign-metadatafiles/${metaDataFile}.sig' --rekor-url 'https://rekor.sigstore.dev'")
    }
}

def cosignVerifyBlob(metaDataFile){
    withCredentials([file(credentialsId: 'cosign-key', variable: 'cosign_pvt')]) {
        def sig 
        sig = sh("cat 'cosign-metadatafiles/${metaDataFile}.sig'")
        echo("## At sig: ${sig}")
        sh("COSIGN_EXPERIMENTAL=1 cosign verify-blob --key '${cosign_pub}' --signature '${sig}' 'cosign-metadatafiles/${metaDataFile}-MetaData.json' --rekor-url 'https://rekor.sigstore.dev'")
    }
}

def cosignClean(imageName){
    sh(script:"cosign clean -f '${imageName}' > cosign_clean_log 2>&1", returnStatus:true)
}

def cosignAttest(imageName){
    withCredentials([file(credentialsId: 'cosign-key', variable: 'cosign_pvt')]) {
        echo "## At 1"
	    dir("cosign-metadatafiles"){
            echo "## At 2"
		    def files = findFiles(glob: '*.json')
            echo "## At 3 files: ${files}"
		    if ("${files.length}" >= 1) {
                echo "## At 4"
                files.each { file ->
                    echo "## At 5 metaDatafile: ${file}"
                    sh("cat ${file}")
                    sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign attest -y --key '${cosign_pvt}' --predicate '${file}' --type \"spdxjson\" ${imageName} --rekor-url 'https://rekor.sigstore.dev'")
                }
		    }
	    }
    }
}

def cosignAttestFile(imageName, metaDataFileName){
    withCredentials([file(credentialsId: 'cosign-key', variable: 'cosign_pvt')]) {
	    dir("cosign-metadatafiles"){
            sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign attest -y --key '${cosign_pvt}' --force --predicate '${metaDataFileName}-MetaData.json' --type \"spdxjson\" ${imageName} --rekor-url 'https://rekor.sigstore.dev'")
        }
    }
}

def cosignVerifyAttestation(imageName){
    withCredentials([file(credentialsId: 'cosign-key', variable: 'cosign_pvt')]) {
        sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign verify-attestation --key '${cosign-key}' --type \"spdxjson\" ${imageName} --policy 'rekor-policy.rego' --rekor-url 'https://rekor.sigstore.dev'")
    }
}

String getEnvtype(branch) {
    String envtype
    if (branch.startsWith("dev")) {
        envtype = "INTEGRATION"
    } else if (branch.startsWith("verify")) {
        envtype = "VERIFY"
    } else if (branch.startsWith("master")) {
        envtype = "PROD"
    } else{
        envtype = "SNAPSHOT"
    }
    return envtype
}

String getAuthorEmailForCommit(String commitId) {
    def gitCommitID = commitId.split("#")[0]
    sh(script: "git log -1 --format='%ae' ${gitCommitID} | head -1", returnStdout: true).trim()
}

String getAuthorEmailForCommit() {
    sh "(git log -n 1 --pretty=format:'%H')".trim()
}
