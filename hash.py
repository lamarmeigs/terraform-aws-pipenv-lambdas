"""Generate a unique hash for all files to be inclued in the Lambda package.

Lambda functions require a zip file containing all the executable application
code. To identify changes to this build package, this script reads all files
affecting the application (local files and the locked dependencies), then
creates a SHA256 hash.

Input & output are configured to work with Terraform's external data resource:
as JSON objects passed via stdin and stdout. It can be invoked via Terraform
like so:

    ```hcl
    data "external" "hash" {
      program = ["python", "${path.module}/hash.py"]
      query = {
        packages     = jsonencode(["src", "common"])
        root         = "../.."
        pipfile_lock = "Pipfile.lock"
      }
    }
    ```

Or via the command line for testing:

    ```shell
    $ cat <EOF > query.json
        {
          "packages": "[\"src\", \"common\"]",
          "root":"../..",
          "pipfile_lock": "Pipfile.lock"
        }
    EOF
    $ cat query.json | python hash.py
    ```

Both will output a JSON object containing the build's hash and suggested file path:

    ```json
    {
      "build_hash": "6871aaea79322af4a4e41774d09fda723274e500af0d902f8268c",
      "filename": "builds/6871aaea79322af4a4e41774d09fda723274e500af0d902f8268c.zip"
    }
    ```
"""

import dataclasses
import hashlib
import json
import os
import sys


@dataclasses.dataclass
class TerraformQuery:
    """Container for Terraform input"""

    packages: list[str]
    pipfile_lock: str
    root: str


def _parse_query() -> TerraformQuery:
    """Read Terraform 'query' argument, passed through stdin as JSON."""
    try:
        query = json.load(sys.stdin)
        query['packages'] = json.loads(query['packages'])
    except json.JSONDecodeError as error:
        raise ValueError('Invalid JSON object passed through STDIN') from error

    expected_keys = {
        field.name
        for field in dataclasses.fields(TerraformQuery)
        if isinstance(field.default, dataclasses._MISSING_TYPE)
    }
    if missing_keys := expected_keys - query.keys():
        raise ValueError(f'JSON object must include keys: {missing_keys}')

    return TerraformQuery(**{key: query[key] for key in expected_keys})


def _get_build_files(query: TerraformQuery) -> list[str]:
    """Obtain an ordered list of all the files to be included in the build."""
    paths = []

    lockfile_path = os.path.join(query.root, query.pipfile_lock)
    if not os.path.isfile(lockfile_path):
        raise ValueError(f'File not found: {lockfile_path}')
    paths.append(lockfile_path)

    for package in query.packages:
        package_path = os.path.join(query.root, package)
        if os.path.isfile(package_path):
            paths.append(package_path)
        elif os.path.isdir(package_path):
            for root, _, files in os.walk(package_path, followlinks=True):
                for file in files:
                    file_path = os.path.join(root, file)
                    paths.append(file_path)
        else:
            raise ValueError(f'Unsupported package type: {package_path}')

    return sorted(paths)


def _generate_hash(file_paths: list[str]) -> str:
    """Generate a unique hash for the contents of the build."""
    build_hash = hashlib.sha256()
    for path in file_paths:
        with open(path, 'rb') as file:
            build_hash.update(file.read())
    return build_hash.hexdigest()


def _output_hash(build_hash: str):
    """Output the hash to STDOUT for Terraform to receive."""
    result = {'build_hash': build_hash, 'filename': f'builds/{build_hash}.zip'}
    json.dump(result, sys.stdout)
    sys.stdout.write('\n')


if __name__ == '__main__':
    query = _parse_query()
    file_paths = _get_build_files(query)
    build_hash = _generate_hash(file_paths)
    _output_hash(build_hash)
