---
title: Code Contributions
order: 3
---

# Code Contribution Guide

## Ways to Contribute

Documentation, code, and other content can all be contributed in the following ways:

- **Pull Request**: Submit code to the repository. It will be merged into the main branch after code review.
- **Issue**: Submit problems or suggestions. After discussion, the team decides whether to implement them and assigns them to developers.

## Code Contribution Workflow

Before submitting code, make sure Git global configuration has been completed locally. The commit email and username configured in local Git **must match the email and username registered on the platform**. Otherwise, incorrect commit records may be generated and cannot be counted in the contributor list.

If you are not sure whether your email and username are correct, check your Git configuration in the terminal:

```shell
git config --global user.name
git config --global user.email
```

If you need to modify them, use the following commands. Replace "Your Name" and "your.email@example.com" with your username and email address:

```shell
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

After completing the configuration, restarting the terminal is recommended to ensure the settings take effect.

1. **Fork the project**: Click Fork in the upper-right corner to copy it to your own repository  
2. **Create a branch**: `git checkout -b feature/your-feature`  
3. **Commit changes**: `git commit -m "feat: describe your changes"`  
4. **Push the branch**: `git push origin feature/your-feature`  
5. **Submit a PR**: Create a Pull Request

Contributed code will go through code review and be merged into the main branch after approval.

## GDScript Style Reference

This project follows the code style rules in Godot's official [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html). The following are reference conventions:

### Formatting

- **Indentation**: Use tabs instead of spaces, with one tab per indentation level
- **Line length**: Keep lines within 100 characters, preferably under 80 characters, otherwise readability may suffer
- **Line endings**: Use LF line endings and keep a trailing newline at the end of files to avoid Git conflicts
- **Encoding**: Use UTF-8 without BOM to avoid garbled text

In general, Godot's default script editor or VSCode can automatically satisfy these formatting requirements. If you use another editor, please pay attention to these rules.

### Naming Conventions

| Element type | Naming style | Example |
|---------|---------|------|
| File name | snake_case | `player_controller.gd` |
| Class name | PascalCase | `class_name PlayerController` |
| Function/variable | snake_case | `func move_player()` |
| Signal | snake_case (past tense) | `signal door_opened` |
| Constant | CONSTANT_CASE | `const MAX_HEALTH = 100` |
| Enum name | PascalCase | `enum GameState` |
| Enum value | CONSTANT_CASE | `IDLE, RUNNING, JUMPING` |

Only English names are allowed in scripts. Do not use other languages, as this may cause problems.

### Commenting Rules

- **Class comments**: Each class needs a comment at the top describing its purpose and usage. This comment is automatically generated into the documentation, so please make it as detailed as possible.
- **Function comments**: Each public function needs a comment above it describing the function, parameters, and return value. Comments may be omitted for private functions or internal utility functions.
- **Variable comments**: Add comments for necessary variables, especially those with specific meanings or uses.
- **Signal comments**: Each signal needs a comment above it describing its purpose and parameters.
- **TODO comments**: If you need to add a todo item, use a `TODO` comment and describe the task and its priority.

## Commit Rules

For an open-source project, the initial learning cost and adaptation process for commit messages does require some effort, but the long-term return is significant. A strict message convention can save developers time in understanding and communication, while also making CHANGELOG generation easier and more standardized.

### Commit Message

This project refers to the Conventional Commits 1.0.0 specification. The format is:

```
<type>(<scope)>: <subject>
```

It contains three fields: `type` (required), `scope` (optional), and `subject` (required).

**`type`** describes the category of the commit. Use one of the following identifiers:

| Type         | Description                              |
| :----------- | :--------------------------------------- |
| **feat**     | New feature                              |
| **fix**      | Bug fix                                  |
| **docs**     | Documentation changes                    |
| **test**     | Add tests or modify existing tests       |
| **ci**       | Changes to CI configuration files and scripts |

**`scope`** describes the affected area of the commit, depending on the project. It can be a module, component, file, and so on.
*   `feat(something): ...`
*   `fix(ui): ...`
*   `docs(readme): ...`
*   If the affected area is broad, it can be omitted or written as `(*)`.

**`subject`** is a short description of the purpose of the commit.

Examples:

```
feat(xxx): add replay feature
fix: fix a crash caused by replay speed being too fast in the replay feature
docs(readme): update readme
```

### Pull Request

A PR (Pull Request) is used to submit your code to the main branch of the main repository. Before submitting a PR, make sure your code meets the following requirements:

1. The code is formatted correctly and follows the project's code style.
2. Commit messages are standardized and follow the Git commit message rules.
3. The submitted code has been tested and has no known issues.

If these conditions are generally satisfied, you can start submitting the PR.

### PR Submission Rules

PR information needs to include the following:

1. **Title**: Briefly and clearly describe the PR content. A Git commit message can be used.
2. **Description**: Describe the PR content in detail, including what the feature does, how it is implemented, and what it affects.
3. **Issue link**: If the PR fixes one or more issues, add the issue links to the PR information.

::: tip Additional suggestions
1. To save maintainers' time and energy, PR descriptions should be as detailed as possible.  
2. Except for simple bug fixes or text changes, PRs should include a substantial body that explains the change thoroughly.  
3. Sometimes commits in a PR need to be modified. Please keep an eye on discussions in the PR comments.  
4. Not every PR will be merged. We apologize in advance for that.
:::

## Code Review

### Review Process

After a PR is submitted, project maintainers will review the code. During review, maintainers may suggest improvements, including but not limited to code style, performance optimization, and security improvements. Please read the suggestions carefully and make changes accordingly.

### Review Standards

During code review, project maintainers follow these standards:

1. **Code style**: Ensure the code style follows the project's style guide.
2. **Performance optimization**: If the code has serious performance issues, provide a performance optimization plan.
3. **Documentation updates**: If code changes affect documentation, update the corresponding documentation.

::: tip Getting help

In most cases, project maintainers will help you resolve problems encountered during code review and ensure your code can be merged smoothly into the main branch. If you need help, please follow the discussions in the PR comments.

:::

## Applying to Become a Maintainer

After making a certain number of PR contributions to the project, you will be eligible to apply to become a maintainer. If you want to become a maintainer, please apply by email using the following steps:

1. Prepare your Git account information, including username and email. This will be used to verify your contribution records and send invitation emails later.

2. Prepare project contribution information, including but not limited to links to PRs that have already been submitted and merged, the number of discussions you participated in, and the number of Issues you reported.

3. Send an email to `konado@godothub.com` with the subject "Apply to become a Konado maintainer". The email should include the information above.

4. If you are willing, you may include a personal introduction in the email, such as your interests, skills, and experience participating in open-source projects. This helps us better understand you.

The project maintainer team will reply to your application as soon as possible. After confirming your contribution records, we will send an invitation email to your mailbox. Please follow the instructions in the email to confirm your maintainer identity and set up repository permissions.

We hope you can become a member of the Konado project and contribute to the open-source community together with us!
