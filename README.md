The boilerplate for a new microservice
======================================

This repository contains a tool for setting up a new microservice code.

The result of this boilerplate will be a list of Git commit messages containing the prepared PHP code based on the
Symfony framework with all tools and Composer packages installed and configured for proper running of the microservice.

How to create a new microservice
--------------------------------

1. Copy `.env.dist` to `.env`.
2. Change `.env` with proper values.
3. Run `sudo ./create-microservice.sh`
4. A new folder named `app` will contain the files and folders of the new microservice along with its Git commit
    messages.
5. Push the content of the `app` folder to a new microservice repository.
6. Add this microservice to the `deployment` repository as it was done for other microservices.
