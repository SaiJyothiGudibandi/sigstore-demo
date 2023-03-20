// Credential ID:
// cosign-key (private key)
// cosign-pub (public key)

def build_metaData

node("jenkins-slave"){

	stage("Checkout"){
		checkout scmGit(branches: [[name: '*/feature-demo-3']], extensions: [], userRemoteConfigs: [[credentialsId: 'devops-team-92', url: 'https://github.com/SaiJyothiGudibandi/sigstore-demo.git']])
        build_metaData = ["environment" : "${env.BRANCH_NAME}", "type": "Checkout", "stage_properties": [ "jenkins": ["ci": [ "build_url": "${env.BUILD_URL}", "job_name": "${env.JOB_NAME}".replaceAll("\\s", "-"), "build_number": "${env.BUILD_ID}", "user": "${env.USER}"]], "scm": ["repo_url": "${env.GIT_URL}", "branch_name": "${env.BRANCH_NAME}", "commit_id": "${env.GIT_COMMIT}"]]]
        createMetadataFile("Code-Build", build_metaData)
	}

	stage("Code Build"){
		docker.image('kartikjena33/cosign:latest').inside('-u 0:0 -v /root/.m2:/root/.m2'){
		    sh("mkdir -p cosign-metadatafiles")
            echo("----- BEGIN Code Build -----")
            sh 'mvn clean install'
            build_metaData = ["environment" : "${env.BRANCH_NAME}"]
            createMetadataFile("Code-Build", build_metaData)
            echo("----- COMPLETED Code Build -----")
        }
	}

	stage('Sonar Scan') {
		docker.image('kartikjena33/cosign:latest').inside('-u 0:0 '){
            echo("----- BEGIN Sonar Scan -----")
            echo("Sonar Scan is in progress")
            build_metaData = ["environment" : "${env.BRANCH_NAME}"]
            createMetadataFile("Sonar-Scan", build_metaData)
            echo("----- COMPLETED Sonar Scan -----")
		}
    }
        
    stage('BlackDuck Scan') {
        echo("----- BEGIN BlackDuck Scan-----")
        echo("BlackDuck Scan is in progress")
        build_metaData = ["environment" : "${env.BRANCH_NAME}"]
        createMetadataFile("BlackDuck-Scan", build_metaData)
        echo("----- COMPLETED BlackDuck Scan-----")
    }

	stage('Docker Build') {
        echo("----- BEGIN Docker Build -----")
        sh 'ls -al'
        sh 'docker build -t us-central1-docker.pkg.dev/citric-nimbus-377218/docker-dev-local/sigstore-demo-image:1.0.0 .'
        build_metaData = ["environment" : "${env.BRANCH_NAME}", "imageName" : "kartikjena33/cosign:latest"]
        createMetadataFile("Docker-Build", build_metaData)
        echo("----- COMPLETED Docker Build -----")
    }

	stage('Docker Publish') {
	    echo("----- BEGIN Docker Publish-----")
	    withCredentials([usernamePassword(credentialsId: 'docker-login', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
            sh 'gcloud auth configure-docker us-central1-docker.pkg.dev --quiet'                      
            sh 'docker push us-central1-docker.pkg.dev/citric-nimbus-377218/docker-dev-local/sigstore-demo-image:1.0.0'
            build_metaData = ["environment" : "${env.BRANCH_NAME}"]
            createMetadataFile("Docker-Build", docker_publish_metaData)
            cosignAttest(imageName, metaDataFile)
	    }
	    echo("----- COMPLETED Docker Publish-----")
    }
        
    stage('Helm Build') {
        docker.image('kartikjena33/cosign:latest').inside('-u 0:0 '){
            echo("----- BEGIN Helm Build -----")
            dir("mychart/"){
                sh("helm package --sign --key 'CI-Pipeline' .")
                sh("helm sigstore upload sigstore-demo-1.0.5.tgz")
            }
            build_metaData = ["environment" : "${env.BRANCH_NAME}"]
            createMetadataFile("Helm-Build", helm_build_metaData)
            echo("----- COMPLETED Helm Build -----")
        }
	}
        
    stage('Helm Publish') {
        docker.image('kartikjena33/cosign:latest').inside('-u 0:0 '){
            echo("----- BEGIN Helm Publish -----")
            dir("mychart/"){
                sh("gcloud auth configure-docker us-central1-docker.pkg.dev --quiet")
                sh("helm sigstore verify sigstore-demo-1.0.5.tgz")
                sh("helm push sigstore-demo-1.0.5.tgz oci://us-central1-docker.pkg.dev/citric-nimbus-377218/helm-dev-local")
            }
            build_metaData = ["environment" : "${env.BRANCH_NAME}"]
            createMetadataFile("Helm-Build", helm_publish_metaData)
            echo("----- COMPLETED Helm Publish -----")
        }
	}
	
	stage('Verfication') {
		docker.image('kartikjena33/cosign:latest').inside('-u 0:0 '){
            echo("----- BEGIN Verfication -----")
            script.dir(cosign-metadatafiles){
		        def files = script.findFiles(glob: '*.json')
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
    sh("ls -al")
    sh("pwd")
    stageName = stageName.replaceAll("[^a-zA-Z0-9-]+", "-").toLowerCase()
    writeJSON(file: "cosign-metadatafiles/${stageName}-MetaData.json", json: metaData, pretty: 4)
    cosignSignBlob(stageName)
    sh("ls -al cosign-metadatafiles/")
    sh("cat cosign-metadatafiles/${stageName}-MetaData.json")
}

def cosignSignBlob(metaDataFile){
    sh("ls -al")
    sh("pwd")
    withCredentials([file(credentialsId: 'cosign-key', variable: 'cosign_pvt')]) {
        sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign sign-blob -y --key '${cosign_pvt}' 'cosign-metadatafiles/${metaDataFile}-MetaData.json' --output-signature 'cosign-metadatafiles/${metaDataFile}.sig' --rekor-url 'https://rekor.sigstore.dev'")
    }
}

def cosignVerifyBlob(metaDataFile){
    sh("ls -al")
    sh("pwd")
    withCredentials([file(credentialsId: 'cosign-key', variable: 'cosign_pvt')]) {
        def sig 
        sig = sh("cat 'cosign-metadatafiles/${metaDataFile}.sig'")
        echo("## At sig: ${sig}")
        sh("COSIGN_EXPERIMENTAL=1 cosign verify-blob --key '${cosign_pub}' --signature '${sig}' 'cosign-metadatafiles/${metaDataFile}-MetaData.json' --rekor-url 'https://rekor.sigstore.dev'")
    }
}

def cosignAttest(imageName, metaDataFile){
    withCredentials([file(credentialsId: 'cosign-key', variable: 'cosign_pvt')]) {
	    script.dir(cosign-metadatafiles){
		    def files = script.findFiles(glob: '*.json')
		    if ("${files.length}" >= 1) {
                files.each { metaDatafile ->
                    sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign attest --key '${cosign_pvt}' --force --predicate 'cosign-metadatafiles/${metaDataFile}-MetaData.json' --type \"spdxjson\" ${imageName} --rekor-url 'https://rekor.sigstore.dev'")
                }
		    }
	    }
    }
}

def cosignVerifyAttestation(imageName){
    withCredentials([file(credentialsId: 'cosign-key', variable: 'cosign_pvt')]) {
        sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign verify-attestation --key '${cosign_pub}' --type \"spdxjson\" ${imageName} --policy 'rekor-policy.rego' --rekor-url 'https://rekor.sigstore.dev'")
    }
}
