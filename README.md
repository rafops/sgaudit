# AWS Security Groups Audit Tool

Reads [CloudMapper](https://github.com/duo-labs/cloudmapper) `account-data` directory and outputs a CSV file with [security groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html) and its associated permissions, network interfaces, addresses, CIDR blocks, vpcs and subnets.

The CSV can be imported to a spreadsheet editor like Google Docs for a convenient auditing of security groups.

## Usage

Build `sgaudit` container:

```
./docker_build.sh
```

Run `sgaudit` specifying the path for `account-data` directory:

```
./docker_run.sh ~/cloudmapper/account-data > output.csv
```
