# kops-in-a-can

A convenience image so that I can easily work with multiple clusters with multiple sets of AWS creds, and easily make my tool versions nice and consistent in the process.

It is just an Ubuntu 16.04 base with a few utilities installed:
* AWS CLI
* Helm
* Kops
* Kubectl

I really just made this for my own convenience, but if you *do* find it useful, awesome. If you find it useful *and* have an idea for how to make it *more* useful, I'm open to suggestions.

## How to use

It's simple: 

1. Update the `docker-compose.yml` file to include the relevant credentials.
2. Run a container: `docker-compose run kops`

Lately I've been working a bit rough and make a different `docker-compose` file for each environment I want to switch between, but I'm sure you can think of something way less kludgey than that.
