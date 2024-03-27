export const unreachable = (input: never): never => {
	throw new Error(`Unreachable, found: '${input}'`);
};
