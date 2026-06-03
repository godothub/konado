---
title: Documentation Contributions
order: 4
---

# Documentation Contribution Guide

## Online Editing

To edit documentation online, click `Edit this page online` in the lower-left corner of the online documentation. Your browser will jump to the corresponding file location in the repository. Click the `Edit` button in the upper-right corner, make your changes, preview the result, and click `Commit changes` once everything looks correct.

After submission, the change will be reviewed and merged into the main repository if approved. In most cases, the online documentation updates automatically after the main repository is merged. If it does not update, refresh the page manually or wait a few minutes after submission and refresh again.

## Local Editing

Documentation changes can be submitted directly to the `master` branch by `submitting a PR`; creating a feature branch is not required.

Before submitting code, make sure Git global configuration has been completed locally:

```shell
git config --global user.name your Git username
git config --global user.email your commit email, which must match the email of your code platform account
```

1. **Fork the project**: Click Fork in the upper-right corner to copy it to your own repository  
2. **Clone the repository**: `git clone`  
3. **Edit documentation**: Find the file you want to modify under the `docs` directory and edit it with Markdown syntax (see [Markdown syntax](https://www.markdownguide.org/basic-syntax))
4. **Commit changes**: `git commit -m "describe your documentation changes"`  
5. **Push the branch**: `git push origin master`

After submission, go to your forked repository page and click the `Pull Request` button to create a PR.

## Previewing Konado Documentation Locally

Konado documentation is built with [VitePress](https://vitepress.dev/). To make sure your documentation changes look as expected, we recommend previewing them locally before submitting code.

### Prerequisite: Install Node.js

VitePress runs on Node.js, so you need to install a compatible Node.js version first:

1. **Version requirement**: Node.js 18.x or later is recommended. An LTS version is best for compatibility.
2. **Download and install**:
   - Visit the official Node.js download page: [https://nodejs.org/](https://nodejs.org/)
   - Choose the installer for your operating system (Windows/macOS/Linux) and follow the wizard. On Windows, selecting "Add to PATH" is recommended.
3. **Verify installation**:
   Open a terminal (Command Prompt/PowerShell on Windows, Terminal on macOS/Linux) and run the following commands to verify that Node.js and npm, the package manager bundled with Node.js, were installed successfully:
   ```shell
   # Check Node.js version
   node -v
   # Check npm version
   npm -v
   ```
   If clear version numbers are printed, such as `v20.10.0` and `10.2.3`, the installation succeeded.

> Optional optimization: If npm dependency downloads are slow, you can configure a China mainland mirror:
> ```shell
> npm config set registry https://registry.npmmirror.com
> ```

### Install Project Dependencies

Enter the root directory of the Konado project and run the following command to install the dependencies required for documentation preview:

```shell
npm install
```

When the command completes without terminal errors, the dependencies have been installed successfully.

### Start the Local Preview Server

After dependencies are installed, run the following command to start the VitePress development server:

```shell
npm run docs:dev
```

### Open the Preview Documentation

After the command starts successfully, the terminal will print output similar to:

```shell
vitepress v1.6.4

➜  Local:   http://localhost:5173/konado/
➜  Network: use --host to expose
➜  press h to show help
```

Open your browser and visit the `Local` address in the output, usually `http://localhost:5173/konado/`, to view the local documentation.

### Additional Notes

1. Live refresh: after modifying documentation, you do not need to restart the service. The browser refreshes automatically and shows the updated result in real time.
2. Port issues: if port `localhost:5173` is occupied, VitePress automatically switches to an available port, such as 5174. Use the actual address printed by the terminal.
3. LAN access: to preview the documentation from other devices on the same network, such as a phone or another computer, run `npm run docs:dev -- --host`. The terminal will print a network-accessible IP address.
4. Stop the server: press `Ctrl + C` in the terminal to stop the local preview server.
