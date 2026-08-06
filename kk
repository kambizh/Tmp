During my original investigation, I found that these are actually two separate concerns.

python_interpreter.python_path in the EE definition affects the EE build. It tells ansible-builder to use /usr/bin/python3.12 when building the execution environment and installing the Python dependencies.

However, it does not configure the default interpreter used by Ansible Core at runtime. Without explicitly configuring the runtime interpreter, Ansible performs interpreter discovery and may execute the custom module using a different Python interpreter (for example platform-python), where ruamel is not available.

In my case, forcing the runtime interpreter to /usr/bin/python3.12 ensured the module used the same Python environment as the one used during the EE build, which resolved the issue.

Please also refer to the Ansible discussion (I'll add the link) and my Confluence investigation if helpful. They document the different runtime contexts, the investigation steps, and the root cause in detail.
