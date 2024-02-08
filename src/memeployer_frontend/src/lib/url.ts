import { HOST } from './config';

export function makeFrontendUrl(canisterId: string) {
	const host = new URL(HOST);

	return `${host.protocol}//${canisterId}.${host.hostname}${host.port ? ':' + host.port : ''}`;
}
