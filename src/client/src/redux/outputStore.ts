export interface OutputStore {
  [outputHash: string]: any
}

export const UPDATE_OUTPUT = 'update-output';

interface UpdateOutputAction {
  type: 'update-output',
  output: string,
  value: any
}

export type OutputAction = UpdateOutputAction;

const INITIAL_OUTPUT_STORE = {};

export const outputReducer = (
  store: OutputStore = INITIAL_OUTPUT_STORE,
  action: OutputAction
) => {
  switch (action.type) {
    case UPDATE_OUTPUT:
      return Object.assign(store, { [action.output]: action.value })
    default:
      return store
  }
}

export const updateOutput = (output_hash: string, value: any): UpdateOutputAction => {
  return {
    type: UPDATE_OUTPUT,
    output: output_hash,
    value: value
  }
}