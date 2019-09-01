import store from './main';

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

export const updateInput = (inputHash: string, value: any) => {
  const state = store.getState();

  store.dispatch({
    type: UPDATE_INPUT,
    input: inputHash,
    value: value
  });

  if (!("updateInput" in state.connection)) return

  state.connection.updateInput(inputHash);
}