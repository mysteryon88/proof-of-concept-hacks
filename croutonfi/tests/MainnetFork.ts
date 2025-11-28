import { Blockchain, RemoteBlockchainStorage, wrapTonClient4ForRemote } from '@ton/sandbox';
import { TonClient4 } from '@ton/ton';

export async function getFork() {
    return await Blockchain.create({
        storage: new RemoteBlockchainStorage(
            wrapTonClient4ForRemote(
                new TonClient4({
                    endpoint: 'https://mainnet-v4.tonhubapi.com',
                }),
            ),
            48879756,
        ),
    });
}
