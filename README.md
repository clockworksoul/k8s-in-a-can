# Kubernetes In A Can

A containerized Kubernetes interaction environment, providing easy version consistency among multiple users and convenient means to work with multiple clusters, environment versions, and/or credentials.

It is just an Ubuntu 16.04 base with a few utilities installed:
* Ansible
* AWS CLI
* Helm
* Istioctl
* Kops
* Kubectl
* Terraform

I really just made this for my own convenience, but if you *do* find it useful, awesome. If you find it useful *and* have an idea for how to make it *more* useful, I'm open to suggestions.

## Injected variables and files

### Environment variables

The following environment values are passed into the container, if set:
* `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`: These are necessary to use `kops`, which doesn't understand the AWS configuration file.
* `ANSIBLE_VAULT_PASSWORD_FILE`: Optional. Used by `ansible-vault`.
* `KOPS_STATE_STORE`: Using `kops` to load kubeconfigs and possibly manage cluster configurations.

### SSH keys

By default, the contents of your `~/.ssh` directory are mounted into the container home directory.

You can override the key source directory by modifying the `VOLUME_SSH` in the script. If you override this value, you'll need to generate ssh keys when you start the container. These will be stored on the host, however, and will only need to be generated once.

### Configuration files

By default the script will generate new configuration files (except for your ssh keys) and store them in a `config` subdirectory. If you want to use existing configuration files (ansible, awscli, helm, kubectl, etc.) change the value of `CONFIGURATION_HOME` in the script to `${HOME}/.` (don't forget the terminal dot!).

## How to configure for a new environment

1. Clone this repo (or even just the `k8s-in-a-can.sh` script) into a meaningfully-named directory:

  * `git clone git@github.com:clockworksoul/k8s-in-a-can.git test-cluster`

  The run script will create a `config` subdirectory to store your configurations.

2. Gather the following information:

  * The address of the `kops` state store: an S3 bucket where the cluster configuration lives (example: `s3://my-kops-state`)
  * AWS credentials for read access to the `kops` state store: an S3 bucket where the cluster configuration lives.

3. The script requires three environment variables. By default these are taken from the user environment, but they can be defined within the script as well.

  * To set these values in your environment:

    1. Add the the following to your `.bash_profile` file, as follows:

      ```
      export AWS_ACCESS_KEY_ID=IHEARTCHEESE
      export AWS_SECRET_ACCESS_KEY=ABCDEFX1234567+fake+key+VIgoDStroyER
      export KOPS_STATE_STORE=s3://my-kops-state

      # You only need to set this if you have an ansible vault password file. You can ignore otherwise.
      # It should not contain a tilde; tildes will make the script sad.
      #
      export ANSIBLE_VAULT_PASSWORD_FILE=/Users/foo/.ansible/vault_password.txt
      ```

      Obviously, use real values. The ones above are just for show.

    2. Reload your .bashrc (or .bash:_profile on a Mac): `. ~/.bashrc` or `. ~/.bash_profile`

  * Alternatively, you can modify the `ENV_*` variables at the top of the `k8s-in-a-can.sh` script.

4. (Optional) Modify locations of injected configurations and environment values by modifying the variables defined at the top of the `k8s-in-a-can.sh` script.

5. Execute the script: `./k8s-in-a-can.sh`. If successful, you should see a `k8s@can:` prompt.

6. Set up your cluster access as detailed below (first fun only).

## How to set up cluster access with k8s-in-a-can (a walk-through)

Once you are in the `k8s@can` environment, you can do configure a new environment as follows:

1. Verify that you have read access to the kops state store: `kops get clusters`. You should see something like the following:

  ```
  k8s@can:~[]$ kops get clusters
  NAME                            CLOUD   ZONES
  my-cluster-01.k8s.local  aws    us-east-2a,us-east-2b,us-east-2c
  ```

2. To export configuration to access the cluster type: `kops export kubecfg my-cluster-01.k8s.local`. Your prompt should update to indicate your current kube context is pointing the the cluster.

3. Finally, test your cluster access with kubectl: `kubectl get ns`.

## Building a new image

A `Makefile` has been provided for your convenience. Simply set the versions of the tool that you want, and do `make build`. The build _does not_ upload the new version to the repository.

**_IMPORTANT: When you build a custom image, always update both the Makefile and the `k8s-in-a-can.sh` scripts with a new label. If you reuse an existing label, the script overwrite it with "offical" image from the repository._**

By convention, the versions of `kops` and `kubectl` should be have been released at about the same time. As long as this is true, the image tag should be the same as the version of `kubectl` used.