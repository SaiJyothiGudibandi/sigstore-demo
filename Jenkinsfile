pipeline {
//     agent { docker { image 'maven:3.8.7-eclipse-temurin-11' } }
    agent any
    stages {
        
        stage('Code Build') {
            steps {
                checkout scmGit(branches: [[name: '*/feature-1']], extensions: [], userRemoteConfigs: [[credentialsId: 'devops-team-92', url: 'https://github.com/SaiJyothiGudibandi/sigstore-demo.git']])
                sh("mkdir -p cosign-metadatafiles")
                sh 'mvn clean install'
                dir("src/"){
                    echo("----- BEGIN Code Build -----")
//                     def code_build_metaData = ["environment" : "${env.BRANCH_NAME}"]
//                     createMetadataFile("Code-Build", code_build_metaData)
                    echo("----- COMPLETED Code Build -----")
                }
            }
        }
        
        stage('Sonar Scan') {
            steps {
                echo("----- BEGIN Sonar Scan -----")
                echo("Sonar Scan is in progress")
//                 def sonar_metaData = ["environment" : "${env.BRANCH_NAME}"]
//                 createMetadataFile("Sonar-Scan", sonar_metaData)
                echo("----- COMPLETED Sonar Scan -----")
            }
        }
        
        stage('BlackDuck Scan') {
            steps {
                echo("----- BEGIN BlackDuck Scan-----")
                echo("BlackDuck Scan is in progress")
//                 def blackduck_metaData = ["environment" : "${env.BRANCH_NAME}"]
//                 createMetadataFile("BlackDuck-Scan", blackduck_metaData)
                echo("----- COMPLETED BlackDuck Scan-----")
            }
        }
        
        stage('Docker Build') {
            steps {
                echo("----- BEGIN Docker Build -----")
                sh 'docker build -t kartikjena33/sigstore-demo-image:1.0.0 .'
//                 def docker_build_metaData = ["environment" : "${env.BRANCH_NAME}"]
//                 createMetadataFile("Docker-Build", docker_build_metaData)
                echo("----- COMPLETED Docker Build -----")
            }
        }
        
        stage('Docker Publish') {
            steps {
                echo("----- BEGIN Docker Publish-----")
                sh 'ls -al'
//                 sh 'docker push kartikjena33/sigstore-demo-image:1.0.0 .'
//                 def docker_publish_metaData = ["environment" : "${env.BRANCH_NAME}"]
//                 createMetadataFile("Docker-Build", docker_publish_metaData)
//                 cosignAttest(metaDataFile, imageName)
                echo("----- COMPLETED Docker Publish-----")
            }
        }
        
        stage('Helm Build') {
            steps {
                echo("----- BEGIN Helm Build -----")
                dir("mychart/"){
                    sh("helm package .")
                }
//                 def helm_build_metaData = ["environment" : "${env.BRANCH_NAME}"]
//                 createMetadataFile("Helm-Build", helm_build_metaData)
                echo("----- COMPLETED Helm Build -----")
            }
        }
        
        stage('Helm Publish') {
            steps {
                echo("----- BEGIN Helm Publish -----")
//                 def helm_publish_metaData = ["environment" : "${env.BRANCH_NAME}"]
//                 createMetadataFile("Helm-Build", helm_publish_metaData)
                echo("----- COMPLETED Helm Publish -----")
            }
        }
        
//         stage('Deploy') {
//             steps {
//                 echo("----- BEGIN Deploy -----")
//                 cosignVerifyBlob(metaDataFile, )
//                 sh 'docker publish -t kartikjena33/sigstore-demo-image:1.0.0 .'
//                 echo("----- COMPLETED Deploy -----")
//             }
//         }
        
    }
}


def createMetadataFile(stageName, metaData) {
    sh("ls -al")
    sh("pwd")
    stageName = stageName.replaceAll("[^a-zA-Z0-9-]+", "-").toLowerCase()
    writeJSON(file: "cosign-metadatafiles/${stageName}-MetaData.json", json: metaData, pretty: 4)
    cosignSignBlob(stageName)
}

// Credential ID:
// cosign-key (private key)
// cosign-pub (public key)


def cosignSignBlob(metaDataFile){
    sh("ls -al")
    sh("pwd")
    withCredentials([file(credentialsId: "cosign-key", variable: cosign_pvt)]) {
        sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign sign-blob  --key '${cosign_pvt}' 'cosign-metadatafiles/${metaDataFile}-MetaData.json' --output-signature 'cosign-metadatafiles/${metaDataFile}.sig' --rekor-url 'https://rekor.sigstore.dev'")
    }
}

def cosignVerifyBlob(metaDataFile){
    sh("ls -al")
    sh("pwd")
    withCredentials([file(credentialsId: "cosign-pub", variable: cosign_pub)]) {
        def sig 
        sig = sh("cat 'cosign-metadatafiles/${metaDataFile}.sig'")
        echo("## At sig: ${sig}")
        sh("COSIGN_EXPERIMENTAL=1 cosign verify-blob --key '${cosign_pub}' --signature '${sig}' 'cosign-metadatafiles/${metaDataFile}-MetaData.json' --rekor-url 'https://rekor.sigstore.dev'")
    }
}

def cosignAttest(metaDataFile, imageName){
    withCredentials([file(credentialsId: "cosign-key", variable: cosign_pvt)]) {
        sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign attest --key '${cosign_pvt}' --force --predicate 'cosign-metadatafiles/${metaDataFile}-MetaData.json' --type \"spdxjson\" ${imageName} --rekor-url 'https://rekor.sigstore.dev'")
    }
}

def cosignVerifyAttestation(imageName){
    withCredentials([file(credentialsId: "cosign-pub", variable: cosign_pub)]) {
        sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign verify-attestation --key '${cosign_pub}' --type \"spdxjson\" ${imageName} --policy 'rekor-policy.rego' --rekor-url 'https://rekor.sigstore.dev'")
    }
}
