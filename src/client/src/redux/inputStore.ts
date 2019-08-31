export interface InputStore {
  [inputHash: string]: any
}

export const UPDATE_INPUT = 'update-input';

interface UpdateInputAction {
  type: 'update-input',
  input: string,
  value: any
}

export type InputAction = UpdateInputAction;

const INITIAL_INPUT_STORE = {};

export const inputReducer = (
  store: InputStore = INITIAL_INPUT_STORE,
  action: InputAction
) => {
  switch (action.type) {
    case UPDATE_INPUT:
      return Object.assign(store, { [action.input]: action.value })
    default:
      return store
  }
}