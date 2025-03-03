import { JSONRPCClient } from 'json-rpc-2.0';
import { ProgramId } from './program';
import { Field, Plaintext } from "@demox-labs/aleo-sdk";
// import { Field, Plaintext } from "@provablehq/sdk"

export const snarkvmNetworks = {
  testnet: "TestnetV0",
  mainnet: "MainnetV0",
  canary: "CanaryV0",
};

export const hashPlaintext = (toHash: string) => {
  try {
    return Plaintext.fromString(toHash).hashBhp256();
  } catch (error) {
    console.log(error);
  }
  // return Plaintext.fromString(
  //   snarkvmNetworks["mainnet"],
  //   toHash
  // ).hashBhp256();
  // return toHash;
};

export const ALEO_URL = 'https://mainnet.aleorpc.com/';
export const ALEOSCAN_URL = 'https://aleoscan.io/api/v1/';

export async function getHeight(): Promise<number> {
  const client = getClient();
  const height = await client.request('getHeight', {});
  return height;
}

export async function getTransactionsForProgram(programId: string, functionName: string): Promise<any> {
  const client = getClient();
  const transaction = await client.request('transactionsForProgram', {
    programId,
    functionName,
    "page": 0,
    "maxTransactions": 1000
  });
  return transaction;
}

export const getClient = () => {
  const client = new JSONRPCClient((jsonRPCRequest: any) =>
    fetch(ALEO_URL, {
      method: 'POST',
      headers: {
        'content-type': 'application/json'
      },
      body: JSON.stringify({ ...jsonRPCRequest })
    }).then((response: any) => {
      if (response.status === 200) {
        // Use client.receive when you received a JSON-RPC response.
        return response.json().then((jsonRPCResponse: any) => client.receive(jsonRPCResponse));
      } else if (jsonRPCRequest.id !== undefined) {
        return Promise.reject(new Error(response.statusText));
      }
    })
  );
  return client;
};

export async function getJSON(url: string): Promise<any> {
  const response = await fetch(url);
  const data = await response.json();
  return data;
}

// Getters

// https://aleoscan.io/api/v1/mapping/get_value/yokin_pool_4_test.aleo/pool_count/0
export async function getPoolCount(): Promise<any> {
  const response = await fetch(`${ALEOSCAN_URL}mapping/get_value/${ProgramId}/pool_count/0`);
  const poolCount = await response.json();
  // returns 2u64
  return parseInt(poolCount.slice(0, -3));
}

export async function getPoolDetails(poolId: number): Promise<any> {
  const response = await fetch(`${ALEOSCAN_URL}mapping/get_value/${ProgramId}/pools/${poolId}`);
  // According to your description, you get back a single string like "{pool_id: 1u64, ...}"
  const rawPoolString = await response.json();
  // If your response is indeed just a string, then parse it:
  const poolObject = parseAleoPoolString(rawPoolString);
  return poolObject;
}

export async function getPoolPaleo(poolId: number): Promise<any> {
  const response = await fetch(`${ALEOSCAN_URL}mapping/get_value/${ProgramId}/pools/${poolId}`);
  // According to your description, you get back a single string like "{pool_id: 1u64, ...}"
  const rawPoolString = await response.json();
  // If your response is indeed just a string, then parse it:
  const poolObject = parseAleoPoolString(rawPoolString);
  return poolObject.total_paleo;
}

export async function getAllPoolDetails(): Promise<any[]> {
  const poolCount = await getPoolCount();
  const pools = Array.from({ length: poolCount }, (_, i) => i + 1);

  // Grab details of each pool in parallel
  const poolDetails = await Promise.all(
    pools.map(async (poolId) => {
      const poolString = await getPoolDetails(poolId);
      // poolString is now already parsed by parseAleoPoolString
      // If getPoolDetails returns the final object, just return it
      return poolString;
    })
  );

  return poolDetails;
}

export async function getAleoPaleoRate(): Promise<any> {
  const url = "https://mainnet.aleorpc.com/";

  const payload = {
    jsonrpc: "2.0",
    id: 1,
    method: "getPrices",
    params: null,
  };

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    throw new Error(`Request failed with status ${response.status}`);
  }

  const data = await response.json();

  const exchangeRate = parseFloat((data.result['ALEO'] / data.result['pALEO']).toFixed(5)) - 0.00001;
  return exchangeRate;
}

// Parser

export function parseMicrocreditsToCredits(microcredits: number): number {
  // Divide by 1,000,000 to get credits
  // toFixed(5) ensures 5 decimal places and returns a string
  // The unary plus (+) converts it back to a number
  return +((microcredits / 1_000_000).toFixed(5));
}

export function parseTimestampToDate(timestamp: number): Date {
  return new Date(timestamp * 1000);
}

export function parseAleoPoolString(poolString: string): any {
  // (Same as above) ...
  // 1. Strip leading/trailing braces
  let trimmed = poolString.trim();
  if (trimmed.startsWith('{')) trimmed = trimmed.slice(1);
  if (trimmed.endsWith('}')) trimmed = trimmed.slice(0, -1);

  // 2. Split on commas to get an array of "key: value"
  const pairs = trimmed.split(',');

  const jsonPairs = pairs.map((pair) => {
    // e.g. "pool_id: 1u64"
    const [rawKey, rawValue] = pair.split(':');
    const key = rawKey.trim();
    const value = rawValue.trim();

    // Check if it ends with "u64" or "u32" and parse the number
    if (value.endsWith('u64') || value.endsWith('u32')) {
      const numericValue = value.split('u')[0]; // everything before 'u64' or 'u32'
      return `"${key}": ${Number(numericValue)}`; // store it as a real number in JSON
    } else {
      // it might be a string like "aleo1qqqq..." or something else
      // just wrap it in quotes for now
      return `"${key}": "${value}"`;
    }
  });

  const jsonString = `{${jsonPairs.join(',')}}`;
  return JSON.parse(jsonString);
}