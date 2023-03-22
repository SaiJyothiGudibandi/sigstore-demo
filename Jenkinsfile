// Credential ID:
// cosign-key (private key)
// cosign-pub (public key)
import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

def build_metaData

node("jenkins-slave"){
    def envType = getEnvtype("${env.BRANCH_NAME}")
    def imageName = "us-central1-docker.pkg.dev/citric-nimbus-377218/docker-dev-local/sigstore-demo-image:1.0.0"
    def helmChart = "mychart/sigstore-demo-1.0.5.tgz"
    def helmPredicateContents =[:]
    def jarNameList = []
    def status
    

    // Chekout
	stage("Checkout"){
		cleanWs()
		def scmVars = checkout scmGit(branches: [[name: '*/feature-3']], extensions: [], userRemoteConfigs: [[credentialsId: 'devops-team-92', url: 'https://github.com/SaiJyothiGudibandi/sigstore-demo.git']])
		def git_commit = getAuthorEmailForCommit()
		def committed_by = getAuthorEmailForCommit("${scmVars.GIT_COMMIT}")
		echo "## At committed_by : ${committed_by}"
		build_metaData = ["environment" : "${envType}", "type": "checkout", "stage_properties": [ "jenkins": ["ci": [ "build_url": "${env.BUILD_URL}", "job_name": "${env.JOB_NAME}".replaceAll("\\s", "-"), "build_number": "${env.BUILD_ID}", "user": "${env.USER}"]], "scm": ["git_url": "${scmVars.GIT_URL}", "branch_name": "${env.BRANCH_NAME}", "committed_by": "${committed_by}"]]]
		helmPredicateContents.put("Checkout", build_metaData)
		createMetadataFile("Checkout", build_metaData)
	}

    // Code Build
	stage("Code Build"){
	    docker.image('kartikjena33/cosign:latest').inside('-u 0:0 -v /root/.m2:/root/.m2'){
		    sh("mkdir -p cosign-metadatafiles")
		    echo("----- BEGIN Code Build -----")
		    sh 'mvn clean install'
		    build_metaData = ["environment" : "${envType}", "type": "codebuild", "stage_properties": [ "running_on": "kartikjena33/cosign:latest", "stage_runner_image_status": "APPROVED", "command_executed": ["mvn clean install"]]]
		    helmPredicateContents.put("Code-Build", build_metaData)
		    createMetadataFile("Code-Build", build_metaData)
		    dir("target"){
			    def jars = findFiles(glob: '*.jar')
			    jars.each{ jarName ->
				    jarNameList.add(jarName)
				    cosignSignArtifact(jarName)
			    }
		    }
		    echo("----- COMPLETED Code Build -----")
	    }
	}

    // Sonar Scan
	stage('Sonar Scan') {
		docker.image('kartikjena33/cosign:latest').inside('-u 0:0 '){
			echo("----- BEGIN Sonar Scan -----")
			echo("Sonar Scan is in progress")
			build_metaData = ["environment" : "${envType}", "type": "sonarquality", "stage_properties":[ "enabled": "true", "scan_results": "pass"]]
			helmPredicateContents.put("Sonar-Scan", build_metaData)
			createMetadataFile("Sonar-Scan", build_metaData)
			echo("----- COMPLETED Sonar Scan -----")
		}
    }

    //  Blackduck Scan 
    stage('BlackDuck Scan') {
	    echo("----- BEGIN BlackDuck Scan-----")
	    echo("BlackDuck Scan is in progress")
	    build_metaData = ["environment" : "${envType}", "type": "blackduckquality", "stage_properties":[ "enabled": "true", "scan_results": "pass"]]
	    helmPredicateContents.put("BlackDuck-Scan", build_metaData)
	    createMetadataFile("BlackDuck-Scan", build_metaData)
	    echo("----- COMPLETED BlackDuck Scan-----")
    }

    // Docker Build
	stage('Docker Build') {
		echo("----- BEGIN Docker Build -----")
		jarNameList.each{ jarName ->
			cosignVerifyArtifact("target/${jarName}")
		}
		sh 'docker build -t us-central1-docker.pkg.dev/citric-nimbus-377218/docker-dev-local/sigstore-demo-image:1.0.0 .'
		build_metaData = ["environment" : "${envType}", "type": "dockerbuild", "stage_properties":[ "running_on": "master", "application_image": "APPROVED", "command_executed": "docker build -t us-central1-docker.pkg.dev/citric-nimbus-377218/docker-dev-local/sigstore-demo-image:1.0.0 ."]]
		helmPredicateContents.put("Docker-Build", build_metaData)
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
			helmPredicateContents.put("Docker-Publish", build_metaData)
			createMetadataFile("Docker-Publish", build_metaData)
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
			    sh("helm package .")
		    }
		    cosignSignHelmChart(helmChart)
		    build_metaData = ["environment" : "${envType}", "type": "helmbuild", "stage_properties":[ "running_on": "kartikjena33/cosign:latest", "stage_runner_image_status": "APPROVED", "command_executed": ["helm package --sign --key 'CI-Pipeline' .", "helm sigstore upload sigstore-demo-1.0.5.tgz"]]]
		    helmPredicateContents.put("Helm-Build", build_metaData)
		    echo("----- COMPLETED Helm Build -----")
	    }
    }

    // Helm Publish
    stage('Helm Publish') {
        docker.image('kartikjena33/cosign:latest').inside('-u 0:0 '){
            echo("----- BEGIN Helm Publish -----")
            cosignVerifyHelmChart(helmChart)
            dir("mychart/"){
                sh("gcloud auth configure-docker us-central1-docker.pkg.dev --quiet")
                sh("helm push sigstore-demo-1.0.5.tgz oci://us-central1-docker.pkg.dev/citric-nimbus-377218/helm-dev-local")
            }
            build_metaData = ["environment" : "${envType}", "type": "helmpublish", "stage_properties":[ "credentials": "jfrog-artifact", "url": "oci://us-central1-docker.pkg.dev/citric-nimbus-377218/helm-dev-local/sigstore-demo-1.0.5.tgz", "checksum": "b3414aa09d1157af794ef65d699bf3b8d2a8bc784aaceb2ceb152d9918de5380"]]
            helmPredicateContents.put("Helm-Publish", build_metaData)
            writeJSON(file: "cosign-metadatafiles/helmChartPredicate-MetaData.json", json: helmPredicateContents, pretty: 4)
            withCredentials([file(credentialsId: 'cosign-key', variable: 'cosign_pvt')]) {
                sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign attest-blob --key '${cosign_pvt}' -y --predicate cosign-metadatafiles/helmChartPredicate-MetaData.json --type \"spdxjson\" ${helmChart} --output-signature ${helmChart}-predicate.sig --rekor-url 'https://rekor.sigstore.dev'")
            }
            echo("----- COMPLETED Helm Publish -----")
        }
	}
    //Tampering docker artifact
    // stage('Tampering docker artifact') {
    //     sh("docker build -t us-central1-docker.pkg.dev/citric-nimbus-377218/docker-dev-local/sigstore-demo-image:1.0.0 -f Dockerfile-new .")
    //     withCredentials([usernamePassword(credentialsId: 'docker-login', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
	// 		sh 'gcloud auth configure-docker us-central1-docker.pkg.dev --quiet'                      
	// 		sh 'docker push us-central1-docker.pkg.dev/citric-nimbus-377218/docker-dev-local/sigstore-demo-image:1.0.0'
	// 	}
	// }

    // Cosign Verfication
	stage('Verfication') {
        try{
            docker.image('kartikjena33/cosign:latest').inside('-u 0:0 '){
                echo("----- BEGIN Verfication -----")
                cosignVerifyAttestation(imageName)
                cosignVerifyAttestionBlob(helmChart)
                echo("----- COMPLETED Helm Publish -----")
            }
        }catch(Exception ex){
            catchError(stageResult: 'FAILURE') {
                status = "FAILED"
                error("Verification Failed.")
            }
        }
	}

    // Deploy
	stage('Deploy') {
        if (status == "FAILED"){
            echo("----- SKIP Deploy -----")
            Utils.markStageSkippedForConditional("Deploy")
        }else{
            echo("----- BEGIN Deploy -----")
            echo("Deploy is in progress")
            echo("----- COMPLETED Deploy -----")
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
    withCredentials([file(credentialsId: 'cosign-pub', variable: 'cosign_pub_key')]) {
        def sig 
        sig = sh(script: "cat '${metaDataFile}.sig'", returnStdout: true).trim()
        sh("COSIGN_EXPERIMENTAL=1 cosign verify-blob --key '${cosign_pub_key}' --signature '${sig}' '${metaDataFile}-MetaData.json' --rekor-url 'https://rekor.sigstore.dev'")
    }
}

def cosignClean(imageName){
    sh(script:"cosign clean -f '${imageName}' > cosign_clean_log 2>&1", returnStatus:true)
}

def cosignAttest(imageName){
    withCredentials([file(credentialsId: 'cosign-key', variable: 'cosign_pvt')]) {
	dir("cosign-metadatafiles"){
	    def files = findFiles(glob: '*.json')
	    if ("${files.length}" >= 1) {
		files.each { file ->
		    def fileName = "${file}".split("-MetaData.json")
		    cosignVerifyBlob("${fileName[0]}")
		    sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign attest -y --key '${cosign_pvt}' --predicate '${file}' --type \"spdxjson\" ${imageName} --rekor-url 'https://rekor.sigstore.dev'")
		}
	    }
	 }
    }
}

def cosignAttestFile(imageName, metaDataFileName){
    withCredentials([file(credentialsId: 'cosign-key', variable: 'cosign_pvt')]) {
	    dir("cosign-metadatafiles"){
            sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign attest -y --key '${cosign_pvt}' --predicate '${metaDataFileName}-MetaData.json' --type \"spdxjson\" ${imageName} --rekor-url 'https://rekor.sigstore.dev'")
        }
    }
}

def cosignVerifyAttestation(imageName){
    try{
        withCredentials([usernamePassword(credentialsId: 'docker-login', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
            sh 'gcloud auth configure-docker us-central1-docker.pkg.dev --quiet'
            withCredentials([file(credentialsId: 'cosign-pub', variable: 'cosign_pub_key')]) {
                sh("ls -al")
                sh("cat rekor-policy.rego")
                sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign verify-attestation --key '${cosign_pub_key}' --type \"spdxjson\" ${imageName} --policy 'rekor-policy.rego' --rekor-url 'https://rekor.sigstore.dev'")
            }
        }
    }catch(Exception ex){
        echo("Verification of Docker failed as the artifact is tampered, hence Skipping Deploy.")
        error("Verification Failed.")
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

def cosignSignHelmChart(helmChartName){
    withCredentials([file(credentialsId: 'cosign-key', variable: 'cosign_pvt')]) {
        sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign sign-blob -y --key '${cosign_pvt}' '${helmChartName}' --output-signature '${helmChartName}.sig' --rekor-url 'https://rekor.sigstore.dev'")
    }
}

def cosignVerifyHelmChart(helmChartName){
    withCredentials([file(credentialsId: 'cosign-pub', variable: 'cosign_pub_key')]) {
        def sig 
        sig = sh(script: "cat '${helmChartName}.sig'", returnStdout: true).trim()
        sh("COSIGN_EXPERIMENTAL=1 cosign verify-blob --key '${cosign_pub_key}' --signature '${sig}' '${helmChartName}' --rekor-url 'https://rekor.sigstore.dev'")
    }
}

def cosignVerifyAttestionBlob(helmChart){
    try{
        withCredentials([file(credentialsId: 'cosign-pub', variable: 'cosign_pub_key')]) {
            sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign verify-blob-attestation --key '${cosign_pub_key}' --type \"spdxjson\" ${helmChart} --signature ${helmChart}-predicate.sig --rekor-url 'https://rekor.sigstore.dev'")
        }
    }catch(Exception ex){
        echo("Verification of Helm chart failed as the artifact is tampered, hence Skipping Deploy.")
        error("Verification Failed.")
    }
}

def cosignSignArtifact(jarFileName){
    withCredentials([file(credentialsId: 'cosign-key', variable: 'cosign_pvt')]) {
        sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign sign-blob -y --key '${cosign_pvt}' '${jarFileName}' --output-signature '${jarFileName}.sig' --rekor-url 'https://rekor.sigstore.dev'")
    }
}

def cosignVerifyArtifact(jarFileName){
    withCredentials([file(credentialsId: 'cosign-pub', variable: 'cosign_pub_key')]) {
        def sig 
        sig = sh(script: "cat '${jarFileName}.sig'", returnStdout: true).trim()
        sh("COSIGN_EXPERIMENTAL=1 cosign verify-blob --key '${cosign_pub_key}' --signature '${sig}' '${jarFileName}' --rekor-url 'https://rekor.sigstore.dev'")
    }
}
