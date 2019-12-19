# Create a folder structure for k8s manifests
# Copy istio-system namespace and CRDs into each GKE cluster folder
resource "null_resource" "exec_create_k8s_repo" {
  provisioner "local-exec" {
    command = <<EOT
    mkdir -p tmp
    gsutil cp gs://${var.tfadmin_proj}/ops/k8s/cloudbuild.yaml tmp/cloudbuild.yaml
    mkdir -p tmp/"${data.terraform_remote_state.ops_gke.outputs.ops_gke_1_name}"
    mkdir -p tmp/"${data.terraform_remote_state.ops_gke.outputs.ops_gke_2_name}"
    mkdir -p tmp/"${data.terraform_remote_state.app1_gke.outputs.dev1_gke_1_name}"
    mkdir -p tmp/"${data.terraform_remote_state.app1_gke.outputs.dev1_gke_2_name}"
    mkdir -p tmp/"${data.terraform_remote_state.app2_gke.outputs.dev2_gke_3_name}"
    mkdir -p tmp/"${data.terraform_remote_state.app2_gke.outputs.dev2_gke_4_name}"

    gsutil cp gs://${var.tfadmin_proj}/ops/istio-"${var.istio_version}"/install/kubernetes/namespace.yaml tmp/"${data.terraform_remote_state.ops_gke.outputs.ops_gke_1_name}"/01_namespace.yaml
    gsutil cp gs://${var.tfadmin_proj}/ops/istio-"${var.istio_version}"/install/kubernetes/namespace.yaml tmp/"${data.terraform_remote_state.ops_gke.outputs.ops_gke_2_name}"/01_namespace.yaml
    gsutil cp gs://${var.tfadmin_proj}/ops/istio-"${var.istio_version}"/install/kubernetes/namespace.yaml tmp/"${data.terraform_remote_state.app1_gke.outputs.dev1_gke_1_name}"/01_namespace.yaml
    gsutil cp gs://${var.tfadmin_proj}/ops/istio-"${var.istio_version}"/install/kubernetes/namespace.yaml tmp/"${data.terraform_remote_state.app1_gke.outputs.dev1_gke_2_name}"/01_namespace.yaml
    gsutil cp gs://${var.tfadmin_proj}/ops/istio-"${var.istio_version}"/install/kubernetes/namespace.yaml tmp/"${data.terraform_remote_state.app2_gke.outputs.dev2_gke_3_name}"/01_namespace.yaml
    gsutil cp gs://${var.tfadmin_proj}/ops/istio-"${var.istio_version}"/install/kubernetes/namespace.yaml tmp/"${data.terraform_remote_state.app2_gke.outputs.dev2_gke_4_name}"/01_namespace.yaml
    
    gsutil cp -r gs://${var.tfadmin_proj}/ops/istiocerts .
    kubectl create secret generic -n istio-system \
    --from-file=istiocerts/ca-cert.pem \
    --from-file=istiocerts/ca-key.pem \
    --from-file=istiocerts/root-cert.pem \
    --from-file=istiocerts/cert-chain.pem \
    --dry-run cacerts -oyaml > 02_istio-cacerts.yaml
    echo $(ls -d tmp/*/) | xargs -n 1 cp 02_istio-cacerts.yaml

    cat > tmp/README.md << EOF
    This is where the k8s manifests live.
    EOT
  }
}


# Add files to repo
resource "null_resource" "exec_initial_commit_k8s_repo" {
  provisioner "local-exec" {
    command = <<EOT
    git config --global user.email $(gcloud auth list --filter=status:ACTIVE --format='value(account)')
    git config --global user.name "terraform"
    git config --global credential.'https://source.developers.google.com'.helper gcloud.sh
    gcloud source repos clone ${data.terraform_remote_state.cloudbuild.outputs.k8s_repo_name} --project=${data.terraform_remote_state.ops_project.outputs.ops_project_id}
    cp -r tmp/. ${data.terraform_remote_state.cloudbuild.outputs.k8s_repo_name}
    cd ${data.terraform_remote_state.cloudbuild.outputs.k8s_repo_name}
    git add . && git commit -am "initial"
    git push -u origin master
    EOT
  }
  depends_on=[null_resource.exec_create_k8s_repo,]
}