pipeline {
//     agent { docker { image 'maven:3.8.7-eclipse-temurin-11' } }
    agent any
    stages {
        
        stage('Code Build') {
            steps {
                dir("src/"){
                    echo("----- BEGIN Code Build -----")
                    sh 'mvn clean install'
                    echo("----- COMPLETED Code Build -----")
                }
            }
        }
        
        stage('Sonar Scan') {
            steps {
                echo("----- BEGIN Sonar Scan-----")
                echo("Sonar Scan is in progress")
                echo("----- COMPLETED Sonar Scan-----")
            }
        }
        
        stage('BlackDuck Scan') {
            steps {
                echo("----- BEGIN BlackDuck Scan-----")
                echo("BlackDuck Scan is in progress")
                echo("----- COMPLETED BlackDuck Scan-----")
            }
        }
        
        stage('Docker Build') {
            steps {
                echo("----- BEGIN Docker Build -----")
                sh 'docker build -t kartikjena33/sigstore-demo-image:1.0.0 .'
                echo("----- COMPLETED Docker Build-----")
            }
        }
        
        stage('Docker Publish') {
            steps {
                echo("----- BEGIN Docker Publish-----")
                sh 'ls -al'
                sh 'docker publish -t kartikjena33/sigstore-demo-image:1.0.0 .'
                echo("----- COMPLETED Docker Publish-----")
            }
        }
        
        stage('Helm Build') {
            steps {
                echo("----- BEGIN Helm Build -----")
                sh 'ls -al'
                sh 'docker publish -t kartikjena33/sigstore-demo-image:1.0.0 .'
                echo("----- COMPLETED Helm Build -----")
            }
        }
        
        stage('Helm Publish') {
            steps {
                echo("----- BEGIN Helm Publish -----")
                sh 'ls -al'
                sh 'docker publish -t kartikjena33/sigstore-demo-image:1.0.0 .'
                echo("----- COMPLETED Helm Publish -----")
            }
        }
        
        stage('Deploy') {
            steps {
                echo("----- BEGIN Deploy -----")
                sh 'ls -al'
                sh 'docker publish -t kartikjena33/sigstore-demo-image:1.0.0 .'
                echo("----- COMPLETED Deploy -----")
            }
        }
        
    }
}
// Credential ID:
// cosign-key (private key)
// cosign-pub (public key)


def cosignSignBlob(metaDataFile){
    withCredentials([file(credentialsId: "cosign-key", variable: cosign_pvt)]) {
        sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign sign-blob  --key '${cosign_pvt}' '${metaDataFile}.json' --output-signature '${metaDataFile}.sig' --rekor-url 'https://rekor.sigstore.dev'")
    }
}

def cosignVerifyBlob(metaDataFile, ){
    withCredentials([file(credentialsId: "cosign-pub", variable: cosign_pub)]) {
        def sig 
        sig = sh("cat '${fileName}.sig'"))
        echo("## At sig: ${sig}")
        sh("COSIGN_EXPERIMENTAL=1 cosign verify-blob --key '${cosign_pub}' --signature '${sig}' '${metaDataFile}.json' --rekor-url 'https://rekor.sigstore.dev'")
    }
}

def cosignAttest(metaDataFile, imageName){
    withCredentials([file(credentialsId: "cosign-key", variable: cosign_pvt)]) {
        sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign attest --key '${cosign_pvt}' --force --predicate ${metaDataFile} --type \"spdxjson\" ${imageName} --rekor-url 'https://rekor.sigstore.dev'")
    }
}

def cosignVerifyAttestation(imageName){
    withCredentials([file(credentialsId: "cosign-pub", variable: cosign_pub)]) {
        sh("COSIGN_EXPERIMENTAL=1 COSIGN_PASSWORD='' cosign verify-attestation --key '${cosign_pub}' --type \"spdxjson\" ${imageName} --policy 'rekor-policy.rego' --rekor-url 'https://rekor.sigstore.dev'")
    }
}
