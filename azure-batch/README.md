# `hp-corex` on Azure Batch

> [!WARNING]
> As of 2026-04-23, the Azure cli command, 'az batch task file download' has an implementation bug. This will have to be manually patched. 
> ```bash
> /opt/az/lib/python3.13/site-packages/azure/cli/command_modules/batch/_validators.py line 242
> ```
> ```python
> # Change: 
> file_name = os.path.basename(namespace.file_name)
> # into: 
> file_name = os.path.basename(namespace.file_path)
> ```
        



## `hp-corex` on Azure Batch

1. Compile the Boost libraries and the ORE binaries. This will take a while. The output will be a tarball in the root directory called `corex-bin-boost-{TARGET_ARCHITECTURE}.tar.gz`;

```bash
./build-ore.sh
```

Alternatively, you can download a pre-built tarball at _____.


> [!IMPORTANT]
> This will compile to target the architecture for the host machine.


2. Gather the python scripts and inputs from the main `corex` repository, this will produce `target/corex.tar.gz`
```bash
./package-corex.sh
```

3. Setup Azure batch to have all the prerequisites to run the benchmark. 
```bash
./azure-setup.sh
```
This will: 
- Create the resource group, `$RESOURCE_GROUP` if it is not already created
- Provision a batch account, `$BATCH_ACCOUNT`, under `$RESOURCE_GROUP`
- Provision a storage account, `$STORAGE_ACCOUNT`, under `$RESOURCE_GROUP`
- Create the container `$CONTAINER_NAME`, if it does not already exist
- Upload `corex-bin-boost-{TARGET_ARCHITECTURE}.tar.gz` and `corex.tar.gz` to the containers
- **Create a SAS token in the working directory `.AZURE_SAS`**, which will be used in later scripts


4. Run the corex benchmark on all target nodes
```bash
./azure-run.sh
```
This will:
- Create a pool dedicated for this run, `$POOL_ID`. If it already exists, it will use the existing pool. 
- Spawn the desired number of tasks (and jobs), `$N_TASKS` under the main batch pool
- TODO: wait for the tasks to finish
- TODO: gather the results of all tasks

