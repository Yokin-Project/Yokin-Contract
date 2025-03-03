import { useState, useEffect, ChangeEvent } from 'react';
import type { NextPageWithLayout } from '@/types';
import { NextSeo } from 'next-seo';
import DashboardLayout from '@/layouts/dashboard/_dashboard';
import Base from '@/components/ui/base';
import { useWallet } from '@demox-labs/aleo-wallet-adapter-react';
import { LeoWalletAdapter } from '@demox-labs/aleo-wallet-adapter-leo';
import Button from '@/components/ui/button';
import {
  Transaction,
  WalletAdapterNetwork,
  WalletNotConnectedError,
} from '@demox-labs/aleo-wallet-adapter-base';
import { ProgramId } from '@/aleo/program';
import { getTransactionsForProgram } from '@/aleo/rpc';
import useSWR from 'swr';

function tryParseJSON(input: string): string | object {
  try {
    return JSON.parse(input);
  } catch (error) {
    return input;
  }
}

const Initialize: NextPageWithLayout = () => {
  const { wallet, publicKey } = useWallet();
  const { data, error, isLoading } = useSWR('intializeCollection', () => getTransactionsForProgram(ProgramId, 'initialize'));
  let [programId, setProgramId] = useState(ProgramId);
  let [functionName, setFunctionName] = useState('initialize');
  let [admin, setAdmin] = useState<string | undefined>(publicKey ?? '');
  let [fee, setFee] = useState<number | undefined>(0.1);
  let [transactionId, setTransactionId] = useState<string | undefined>();
  let [status, setStatus] = useState<string | undefined>();

  useEffect(() => {
    setAdmin(publicKey ?? '');
  }, [publicKey]);

  useEffect(() => {
    let intervalId: NodeJS.Timeout | undefined;

    if (transactionId) {
      intervalId = setInterval(() => {
        getTransactionStatus(transactionId!);
      }, 1000);
    }

    return () => {
      if (intervalId) {
        clearInterval(intervalId);
      }
    };
  }, [transactionId]);

  const handleSubmit = async (event: ChangeEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!publicKey) throw new WalletNotConnectedError();

    const aleoTransaction = Transaction.createTransaction(
      publicKey,
      'mainnet',
      programId,
      functionName,
      [admin],
      Math.floor(fee! * 1_000_000)!,
      false
    );

    console.log(aleoTransaction);

    const txId =
      (await (wallet?.adapter as LeoWalletAdapter).requestTransaction(
        aleoTransaction
      )) || '';
    setTransactionId(txId);

    console.log("txId", txId);
  };

  const getTransactionStatus = async (txId: string) => {
    const status = await (
      wallet?.adapter as LeoWalletAdapter
    ).transactionStatus(txId);
    setStatus(status);
  };

  return (
    <>
      <NextSeo
        title="Initialize"
        description="Initialize Yokin Contract"
      />
      <Base>
        {isLoading && <p>Loading...</p>}
        {!isLoading && data && data[0] &&
          <div className="relative flex w-full flex-col rounded-full md:w-auto text-center p-8">
            {`${ProgramId}`} is already initialized <a target="_blank" rel="noopener noreferrer" className="underline mt-4" href={`https://aleoscan.io/program?id=${ProgramId}`}>View on Aleoscan</a>
          </div>
        }
        {!isLoading && (!data || !data[0]) &&
          <form
            noValidate
            role="search"
            onSubmit={handleSubmit}
            className="relative flex w-full flex-col rounded-full md:w-auto"
          >
            <label className="flex w-full items-center justify-between py-4">
              Program ID:
              <input
                className="h-11 w-10/12 appearance-none rounded-lg border-2 border-gray-200 bg-transparent py-1 text-sm tracking-tighter text-gray-900 outline-none transition-all placeholder:text-gray-600 focus:border-gray-900 ltr:pr-5 ltr:pl-10 rtl:pr-10 dark:border-gray-600 dark:text-white dark:placeholder:text-gray-500 dark:focus:border-gray-500"
                placeholder="credits.aleo"
                onChange={(event) => setProgramId(event.currentTarget.value)}
                value={programId}
              />
            </label>

            <label className="flex w-full items-center justify-between py-4">
              Function Name:
              <input
                className="h-11 w-10/12 appearance-none rounded-lg border-2 border-gray-200 bg-transparent py-1 text-sm tracking-tighter text-gray-900 outline-none transition-all placeholder:text-gray-600 focus:border-gray-900 ltr:pr-5 ltr:pl-10 rtl:pr-10 dark:border-gray-600 dark:text-white dark:placeholder:text-gray-500 dark:focus:border-gray-500"
                placeholder="join"
                onChange={(event) => setFunctionName(event.currentTarget.value)}
                value={functionName}
              />
            </label>

            <label className="flex w-full items-center justify-between py-4">
              Admin:
              <input
                className="h-11 w-10/12 appearance-none rounded-lg border-2 border-gray-200 bg-transparent py-1 text-sm tracking-tighter text-gray-900 outline-none transition-all placeholder:text-gray-600 focus:border-gray-900 ltr:pr-5 ltr:pl-10 rtl:pr-10 dark:border-gray-600 dark:text-white dark:placeholder:text-gray-500 dark:focus:border-gray-500"
                placeholder="aleo1..."
                onChange={(event) => setAdmin(event.currentTarget.value)}
                value={admin ?? ''}
              />
            </label>

            <label className="flex w-full items-center justify-between py-4">
              Fee:
              <input
                type="number"
                className="h-11 w-10/12 appearance-none rounded-lg border-2 border-gray-200 bg-transparent py-1 text-sm tracking-tighter text-gray-900 outline-none transition-all placeholder:text-gray-600 focus:border-gray-900 ltr:pr-5 ltr:pl-10 rtl:pr-10 dark:border-gray-600 dark:text-white dark:placeholder:text-gray-500 dark:focus:border-gray-500"
                placeholder="Fee (in credits)"
                onChange={(event) => {
                  const parsed = parseFloat(event.target.value);
                  setFee(!Number.isNaN(parsed) ? parsed : undefined);
                }}
                value={fee ?? ''}
              />
            </label>
            <div className="flex items-center justify-center">
              <Button
                disabled={
                  !publicKey || !programId || !functionName || fee === undefined
                }
                type="submit"
                className="shadow-card dark:bg-gray-700 md:h-10 md:px-5 xl:h-12 xl:px-7"
              >
                {!publicKey ? 'Connect Your Wallet' : 'Submit'}
              </Button>
            </div>
          </form>
        }
        {transactionId && (
          <div>
            <div>{`Transaction status: ${status}`}</div>
          </div>
        )}
      </Base>
    </>
  );
};

Initialize.getLayout = function getLayout(page) {
  return <DashboardLayout>{page}</DashboardLayout>;
};

export default Initialize;
