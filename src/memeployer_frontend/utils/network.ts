export interface NetworkConfig {
  canisterIds: () => Record<string, string>;
  host: (() => string) | string;
  internetIdentity:
    | ((canisterIds: Record<string, string>, hostUrl: string) => string)
    | string;
}

export class Networks<N extends Record<string, NetworkConfig>> {
  constructor(private networks: N) {}

  isValidNetwork(network: any): network is keyof N {
    return network in this.networks;
  }

  getConfig(network: keyof N): {
    canisterIds: Record<string, string>;
    host: string;
    internetIdentity: string;
  } {
    const config = this.networks[network];
    const canisterIds = config.canisterIds();
    const host =
      typeof config.host === "function" ? config.host() : config.host;
    const internetIdentity =
      typeof config.internetIdentity === "function"
        ? config.internetIdentity(canisterIds, host)
        : config.internetIdentity;
    return {
      canisterIds,
      host,
      internetIdentity,
    };
  }
}

export function getCanisterIds(
  canisterIdsObject: any,
  network: string
): Record<string, string> {
  if (canisterIdsObject && typeof canisterIdsObject === "object") {
    const canisterIds: Record<string, string> = {};
    for (const [canisterName, config] of Object.entries(canisterIdsObject)) {
      if (!config || typeof config !== "object") {
        throw Error(
          `Invalid canister_ids.json file for network ${network} at canister ${canisterName}`
        );
      }
      if (network in config) {
        canisterIds[canisterName] = config[network];
      }
    }
    return canisterIds;
  } else {
    throw Error(`Invalid canister_ids.json file for network: ${network}`);
  }
}
