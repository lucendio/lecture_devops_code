#!/usr/bin/env groovy


pipeline {

    agent {
        label 'docker'
    }

    stages {
        stage( 's2' ){
            steps {
                script {
                    def oci = docker.image('alpine/helm:3.0.0')
                    oci.inside("--entrypoint=''"){
                        sh 'helm version'
                    }
                }
            }
        }
    }

}
