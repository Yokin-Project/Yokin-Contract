import type { NextPageWithLayout } from '@/types';
import { NextSeo } from 'next-seo';
import DashboardLayout from '@/layouts/dashboard/_dashboard';
import Button from '@/components/ui/button';
import routes from '@/config/routes';
import { WalletMultiButton } from '@demox-labs/aleo-wallet-adapter-reactui';

type SectionProps = {
  title: string;
  bgColor: string;
  sectionWidth?: string;
};

export function Section({
  title,
  bgColor,
  children,
  sectionWidth,
}: React.PropsWithChildren<SectionProps>) {
  return (
    <div className="mb-3">
      <div className={`rounded-lg ${bgColor}`}>
        <div className="relative flex items-center justify-between gap-4 p-4">
          <div className={`items-center ltr:mr-6 rtl:ml-6 ${sectionWidth}`}>
            <div>
              <span className="block text-xs font-medium uppercase tracking-wider text-gray-900 dark:text-white sm:text-sm">
                {title}
              </span>
              <span className="mt-1 hidden text-xs tracking-tighter text-gray-600 dark:text-gray-400 sm:block">
                {children}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

const GettingStartedPage: NextPageWithLayout = () => {
  return (
    <>
      <NextSeo
        title="Leo Wallet | Available Routes"
        description="List of current routes and their descriptions for Leo Wallet"
      />
      <div className="mx-auto w-full px-4 pt-8 pb-14 sm:px-6 sm:pb-20 sm:pt-12 lg:px-8 xl:px-10 2xl:px-0 flex flex-row flex-wrap gap-x-6 gap-y-10 items-center justify-center">
        <Section title="/initialize" bgColor="bg-white shadow-card dark:bg-light-dark">
          ADMIN: Initialize the Yokin Pool Contract.<br /><br />
          <a href={`${routes.initialize}`}>
            <Button>Initialize</Button>
          </a>
        </Section>
        <Section
          title="/createPool"
          bgColor="bg-white shadow-card dark:bg-light-dark"
        >
          ADMIN: Create a new pool.<br /><br />
          <a href={`${routes.createPool}`}>
            <Button>Create Pool</Button>
          </a>
        </Section>
        <Section
          title="/getPool"
          bgColor="bg-white shadow-card dark:bg-light-dark"
        >
          USER: View existing pool.<br /><br />
          <a href={`${routes.getPool}`}>
            <Button>Get Pool</Button>
          </a>
        </Section>
        <Section
          title="/deposit"
          bgColor="bg-white shadow-card dark:bg-light-dark"
        >
          USER: Deposit funds into a pool.<br /><br />
          <a href={`${routes.deposit}`}>
            <Button>Deposit</Button>
          </a>
        </Section>
        <Section title="/startSlowWithdraw" bgColor="bg-white shadow-card dark:bg-light-dark">
          ADMIN: Start a slow withdrawal from Pondo to Yokin Pool.<br /><br />
          <a href={`${routes.startSlowWithdraw}`}>
            <Button>Start Slow Withdrawal</Button>
          </a>
        </Section>
        <Section title="/claimWithdraw" bgColor="bg-white shadow-card dark:bg-light-dark">
          ADMIN: Claim a slow withdrawal from Pondo to Yokin Pool.<br /><br />
          <a href={`${routes.claimSlowWithdraw}`}>
            <Button>Claim Withdrawal</Button>
          </a>
        </Section>
        <Section
          title="/randomWinner"
          bgColor="bg-white shadow-card dark:bg-light-dark"
        >
          ADMIN: Random a winner for your liquidity pool contests.<br /><br />
          <a href={`${routes.randomWinner}`}>
            <Button>Random Winner</Button>
          </a>
        </Section>
        <Section
          title="/withdraw"
          bgColor="bg-white shadow-card dark:bg-light-dark"
        >
          USER: Withdraw funds from a pool.<br /><br />
          <a href={`${routes.withdraw}`}>
            <Button>Withdraw</Button>
          </a>
        </Section>
      </div>
    </>
  );
};

GettingStartedPage.getLayout = function getLayout(page) {
  return <DashboardLayout>{page}</DashboardLayout>;
};

export default GettingStartedPage;