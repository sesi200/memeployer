export type Deployment =
	| {
			type: 'frontend';
			canisterId: string;
	  }
	| {
			type: 'icrc';
			name: string;
			canisterId: string;
	  };

export function loadDeployments(): Deployment[] {
	const deployments = localStorage.getItem('deployments');
	if (deployments) {
		return JSON.parse(deployments);
	}
	return [];
}

export function saveDeployment(deployment: Deployment) {
	const deployments = loadDeployments();
	deployments.push(deployment);
	localStorage.setItem('deployments', JSON.stringify(deployments));
}
