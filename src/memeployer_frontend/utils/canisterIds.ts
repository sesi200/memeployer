import { readFileSync } from "fs";
import { getCanisterIds } from "./network";

export function readCanisterIds(
  url: string,
  network: string
): Record<string, string> {
  return getCanisterIds(
    JSON.parse(
      readFileSync(url, {
        encoding: "utf-8",
      })
    ),
    network
  );
}

export function canisterIdsToVite(
  canisterIds: Record<string, string>,
  prefix: string = "VITE_",
  suffix: string = "_CANISTER_ID"
): Record<string, string> {
  const viteCanisterIds: Record<string, string> = {};

  for (const [canisterName, canisterId] of Object.entries(canisterIds)) {
    viteCanisterIds[`${prefix}${canisterName.toUpperCase()}${suffix}`] =
      canisterId;
  }

  return viteCanisterIds;
}
