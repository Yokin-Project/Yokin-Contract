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

function tryParseJSON(input: string): string | object {
  try {
    return JSON.parse(input);
  } catch (error) {
    return input;
  }
}

const CreatePool: NextPageWithLayout = () => {
  const { wallet, publicKey } = useWallet();

  let [programId, setProgramId] = useState(ProgramId);
  let [functionName, setFunctionName] = useState('create_pool_public');
  let [currentTimestamp, setCurrentTimestamp] = useState<number | undefined>(
    Date.now()
  );
  let [depositDeadlineTimestamp, setDepositDeadlineTimestamp] =
    useState<number | undefined>(Date.now() + 1000 * 60 * 5); // 5 minutes
  let [withdrawDeadlineTimestamp, setWithdrawDeadlineTimestamp] =
    useState<number | undefined>(Date.now() + 1000 * 60 * 60 * 24 * 7); // 7 days
  let [fee, setFee] = useState<number | undefined>(0.1);
  let [transactionId, setTransactionId] = useState<string | undefined>();
  let [status, setStatus] = useState<string | undefined>();

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
      [Math.floor(currentTimestamp! / 1000) + "u32", Math.floor(depositDeadlineTimestamp! / 1000) + "u32", Math.floor(withdrawDeadlineTimestamp! / 1000) + "u32"],
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
        title="Create Pool"
        description="CreatePool to Yokin Pool"
      />
      <Base>
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
            Current Timestamp UTC:
            <input
              type="datetime-local"
              className="h-11 w-10/12 appearance-none rounded-lg border-2 border-gray-200 bg-transparent py-1 text-sm tracking-tighter text-gray-900 outline-none transition-all placeholder:text-gray-600 focus:border-gray-900 ltr:pr-5 ltr:pl-10 rtl:pr-10 dark:border-gray-600 dark:text-white dark:placeholder:text-gray-500 dark:focus:border-gray-500"
              placeholder="dd/mm/yyyy hh:mm"
              onChange={(event) =>
                setCurrentTimestamp(new Date(event.currentTarget.value).getTime())
              }
              value={
                currentTimestamp
                  ? new Date(currentTimestamp).toISOString().slice(0, 16)
                  : ''
              }
            />
          </label>

          <label className="flex w-full items-center justify-between py-4">
            Deposit Deadline UTC:
            <input
              type="datetime-local"
              className="h-11 w-10/12 appearance-none rounded-lg border-2 border-gray-200 bg-transparent py-1 text-sm tracking-tighter text-gray-900 outline-none transition-all placeholder:text-gray-600 focus:border-gray-900 ltr:pr-5 ltr:pl-10 rtl:pr-10 dark:border-gray-600 dark:text-white dark:placeholder:text-gray-500 dark:focus:border-gray-500"
              placeholder="dd/mm/yyyy hh:mm"
              onChange={(event) =>
                setDepositDeadlineTimestamp(new Date(event.currentTarget.value).getTime())
              }
              value={
                depositDeadlineTimestamp
                  ? new Date(depositDeadlineTimestamp).toISOString().slice(0, 16)
                  : ''
              }
            />
          </label>

          <label className="flex w-full items-center justify-between py-4">
            Withdrawable time UTC:
            <input
              type="datetime-local"
              className="h-11 w-10/12 appearance-none rounded-lg border-2 border-gray-200 bg-transparent py-1 text-sm tracking-tighter text-gray-900 outline-none transition-all placeholder:text-gray-600 focus:border-gray-900 ltr:pr-5 ltr:pl-10 rtl:pr-10 dark:border-gray-600 dark:text-white dark:placeholder:text-gray-500 dark:focus:border-gray-500"
              placeholder="dd/mm/yyyy hh:mm"
              onChange={(event) =>
                setWithdrawDeadlineTimestamp(new Date(event.currentTarget.value).getTime())
              }
              value={
                withdrawDeadlineTimestamp
                  ? new Date(withdrawDeadlineTimestamp).toISOString().slice(0, 16)
                  : ''
              }
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

        {transactionId && (
          <div>
            <div>{`Transaction status: ${status}`}</div>
          </div>
        )}
      </Base>
    </>
  );
};

CreatePool.getLayout = function getLayout(page) {
  return <DashboardLayout>{page}</DashboardLayout>;
};

export default CreatePool;
