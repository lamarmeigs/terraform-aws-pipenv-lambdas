#!/usr/bin/env python3
"""Build a zip file with the service's executable code.

Lambda functions require a zip file containing all the executable application
code. This script creates such a file locally, adding all of the service's
packages along with its locked dependencies. The latter are installed via the
AWS-maintained docker image for the desired Lambda runtime.

The script is intended to be invoked via Terraform's `local_exec` provisioner
on a `null_resource` object, like so:

    ```hcl
    resource "null_resource" "build" {
      triggers = {
        hash = data.external.build_hash.result.build_hash
      }

      provisioner "local-exec" {
        interpreter = ["python"]
        command     = <<-EOT
          ${path.module}/build.py ${data.external.build_hash.result.filename} \
            --packages ${join(" ", var.packages)} \
            --pipfile_lock ${var.pipfile_lock_path} \
            --root ${var.root} \
            --runtime ${var.runtime}
        EOT
      }
    }
    ```

Or via the command line for testing:

    ```shell
    $ python build.py builds/some_hash.zip \
    >   --pipfile_lock Pipfile.lock \
    >   --packages src common \
    >   --root "../.." \
    >   --runtime python3.10
    ```

Logs are emitted to stderr to ensure visibilty during Terraform runs. The log
level can be modified by setting the LOG_LEVEL environment variable.

Note that this script must be run in an environment with Python, Pip, Pipenv,
and Docker installed.
"""
import argparse
import logging
import os
import platform
import shlex
import subprocess
import sys
import tempfile
import zipfile

logger = logging.getLogger()
logger.addHandler(logging.StreamHandler(stream=sys.stderr))
logger.setLevel(
    getattr(logging, os.environ.get('LOG_LEVEL', 'INFO').upper(), logging.INFO)
)


def _list_files(directory: str) -> list[str]:
    """Generate a list of all files in the given directory and its children."""
    paths = []
    for current_directory, _, files in os.walk(directory, followlinks=True):
        for file in files:
            file_path = os.path.join(current_directory, file)
            paths.append(file_path)
    return sorted(paths)


def _get_service_files(root: str, packages: list[str]) -> list[str]:
    """Generate a list of all the local files to be included in the build."""
    paths = []
    for package in packages:
        package_path = os.path.join(root, package)
        if os.path.isfile(package_path):
            paths.append(package_path)
        elif os.path.isdir(package_path):
            paths.extend(_list_files(package_path))
        else:
            raise ValueError(f'Unsupported package type: {package_path}')
    return paths


def _add_files_to_build(build_zip: zipfile.ZipFile, root: str, file_paths: list[str]):
    """Add all given local files to the open zip file with appropriate permissions."""
    for path in file_paths:
        build_path = os.path.relpath(path, start=root)
        zinfo = zipfile.ZipInfo(build_path)
        zinfo.external_attr = 0o644 << 16

        logger.debug(f'Zipping {build_path}...')
        with open(path, 'rb') as src:
            build_zip.writestr(zinfo, src.read())


def _install_dependencies(pipfile_lock: str, target_directory: str, runtime: str):
    """Install dependencies to the target directory via the runtime's docker image."""
    requirements_file = os.path.join(target_directory, 'requirements.txt')
    with open(requirements_file, 'w', encoding='utf-8') as requirements:
        subprocess.run(
            ['pipenv', 'requirements'],
            stdout=requirements,
            cwd=os.path.dirname(pipfile_lock),
            check=True,
        )

    docker_command = ['docker', 'run', '--rm']
    if platform.machine().lower().startswith('arm'):
        docker_command.extend(['--platform', 'linux/amd64'])

    docker_work_directory = '/var/task'
    docker_command.extend(['-w', docker_work_directory])
    docker_command.extend(
        ['-v', f'{os.path.abspath(target_directory)}:{docker_work_directory}:z']
    )
    docker_command.extend(['-e CODEARTIFACT_AUTH_TOKEN'])

    pip_cache = (
        subprocess.run(
            ['pip', 'cache', 'dir'],
            capture_output=True,
            check=True,
        )
        .stdout.decode()
        .strip()
    )
    docker_command.extend(['-v', f'{pip_cache}:/root/.cache/pip:z'])

    image = f'public.ecr.aws/sam/build-{runtime}'
    docker_command.append(image)

    docker_requirements_file = os.path.join(docker_work_directory, 'requirements.txt')
    install_command = ['pip', 'install', '--no-compile']
    install_command.extend(['--requirement', docker_requirements_file])
    install_command.extend(['--target', docker_work_directory])
    chown_command = [
        'chown',
        '-R',
        f'{os.getuid()}:{os.getgid()}',
        docker_work_directory,
    ]
    shell_command = ' '.join(
        [shlex.quote(arg) for arg in install_command]
        + ['&&']
        + [shlex.quote(arg) for arg in chown_command]
    )
    docker_command.extend(['/bin/sh', '-c', f"'{shell_command}'"])

    docker_command = ' '.join(docker_command)
    logger.debug(docker_command)
    subprocess.run(docker_command, check=True, shell=True)
    subprocess.run(['rm', requirements_file], check=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--pipfile_lock',
        required=True,
        help='Path to the Pipfile.lock to use during builds, relative to the root',
    )
    parser.add_argument(
        '--packages',
        nargs='+',
        required=True,
        help='List of local packages to include in the build, relative to the root',
    )
    parser.add_argument(
        '--root',
        required=True,
        help=(
            'Path to the root of the build, from which Pipfile.lock and all '
            'local packages may be found'
        ),
    )
    parser.add_argument(
        '--runtime',
        required=True,
        help='The Lambda runtime, through whose docker image to install dependencies',
    )
    parser.add_argument('filename', help='Path at which to build the zip file')

    args = parser.parse_args()

    if os.path.isfile(args.filename):
        logger.info('Reusing existing build')
        sys.exit(0)

    logger.info('Creating build directory...')
    os.makedirs(os.path.dirname(args.filename), exist_ok=True)

    try:
        with zipfile.ZipFile(
            args.filename, 'w', compression=zipfile.ZIP_DEFLATED
        ) as build:
            logger.info('Adding service packages to build...')
            service_files = _get_service_files(args.root, args.packages)
            _add_files_to_build(build, args.root, service_files)

            with tempfile.TemporaryDirectory(dir=os.environ.get('RUNNER_TEMP')) as temp:
                pipfile_lock = os.path.join(args.root, args.pipfile_lock)
                logger.info('Installing dependencies...')
                _install_dependencies(pipfile_lock, temp, args.runtime)
                dependency_files = _list_files(temp)
                logger.info('Adding dependencies to build...')
                _add_files_to_build(build, temp, dependency_files)
    except:  # noqa: E722
        logger.exception('Build failed')
        os.unlink(args.filename)
        sys.exit(1)
