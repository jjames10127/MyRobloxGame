# Basketball AFK RNG Arena Development

This project uses Rojo for Roblox Studio syncing and VS Code for editing Luau source.

## Required Tools

- Roblox Studio
- Rojo
- VS Code
- Luau Language Server
- Selene
- StyLua

## Check Tool Versions

```sh
rojo --version
stylua --version
selene --version
```

## Project Structure

```text
src
├─ ReplicatedStorage
│  ├─ Remotes
│  └─ Shared
│     ├─ Config
│     └─ Utility
├─ ServerScriptService
│  ├─ Services
│  └─ ServerMain.server.lua
├─ StarterPlayer
│  └─ StarterPlayerScripts
│     └─ ClientMain.client.lua
└─ StarterGui
   └─ MainUI
```

`Shared` is a folder. Do not recreate `src/ReplicatedStorage/Shared.lua`.

## Start Rojo

```sh
rojo serve
```

If you want to be explicit:

```sh
rojo serve default.project.json
```

## Connect Roblox Studio

1. Open Roblox Studio.
2. Open the Rojo plugin.
3. Connect to localhost.
4. Press Play in Studio to test runtime behavior.

## Generate Sourcemap

```sh
rojo sourcemap default.project.json --include-non-scripts --output sourcemap.json
```

The sourcemap helps Luau Language Server understand the Rojo data model tree.
If you only need scripts, this shorter command also works:

```sh
rojo sourcemap default.project.json --output sourcemap.json
```

## Reload VS Code

After changing `.vscode/settings.json` or regenerating the sourcemap:

1. Press `Command + Shift + P`.
2. Run `Developer: Reload Window`.

## Format

```sh
stylua src
```

## Lint

```sh
selene src
```

If Selene cannot collect the Roblox standard library, generate the local Roblox API standard library once:

```sh
selene generate-roblox-std
```

## Local Checks vs Roblox Runtime

Config and utility modules are mostly pure Lua tables/helper functions and can be checked locally.

Server and client scripts that call Roblox APIs such as `game:GetService`, `Instance.new`, `Color3.fromRGB`,
`UDim2.fromOffset`, `Enum.Font`, `DataStoreService`, `Players`, `ReplicatedStorage`, and `Workspace` must be tested in
Roblox Studio Play mode. Standalone local Luau does not provide the Roblox `game` global, so `game:GetService` failing
outside Studio is expected and is not a project bug.

DataStore/API behavior must be tested in Roblox Studio. For persistence in Studio, publish the experience and enable
Studio API access.
