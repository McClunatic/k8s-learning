# Nuxt 3 Minimal Starter

Look at the [Nuxt 3 documentation](https://nuxt.com/docs/getting-started/introduction) to learn more.

## Setup

Make sure to install the dependencies:

```bash
# yarn
yarn install

# npm
npm install

# pnpm
pnpm install --shamefully-hoist
```

## Development Server

Start the development server on <http://localhost:3000>

```bash
npm run dev
```

## Production

Build the application for production:

```bash
npm run build
```

Locally preview production build:

```bash
npm run preview
```

Check out the [deployment documentation](https://nuxt.com/docs/getting-started/deployment) for more information.

## k8s-learning Documentation

### Creating a Nuxt app

The `nuxt-app/` directory in this repository was created following
[Nuxt Installation](https://nuxt.com/docs/getting-started/installation)
guidance. To run the "Welcome to Nuxt" app, with Node.js installed, run

```shell
> npm run dev -- -o
```

### Building the Nuxt app container

The `Dockerfile` defines a simple recipe for containerizing the "Welcome to
Nuxt" app. To build the container, run:

```shell
> docker build -t <username>/nuxt-app .
```

### Publishing to Docker Hub

Kubernetes expects images in its `.yaml` file object specs
(e.g., one specifying a **Deployment**) to be *hosted*. By default, it will
attempt to fetch image names from Docker Hub. To make sure the `nuxt-app`
image can be fetched as part of creating a Deployment, log in to Docker
Hub and push the image as follows:

```shell
> docker login -u <username> -p <password>
```

> If you don't have a Docker Hub account, create one to complete this!

```shell
> docker push <username>/nuxt-app
```

### Creating a Nuxt app deployment

The `nuxt-app.deployment.yaml` defines the defines the Kubernetes Deployment
for the "Welcome to Nuxt" app, using the published `nuxt-app` container
image. To create the Deployment, there are several different options
discussed in detail in
[Kubernetes Object Management](https://kubernetes.io/docs/concepts/overview/working-with-objects/object-management/).
The following example takes a declarative approach:

```shell
kubectl apply -f nuxt-app.deployment.yaml
```
