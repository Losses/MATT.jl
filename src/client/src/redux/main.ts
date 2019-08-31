import { createStore, combineReducers } from 'redux';
import { uiReducer, UIStore, INITIAL_UI_STORE } from './uiStore';

export type HashTable = { [hash: string]: string[] };

export interface InputState<T extends {}> {
  value: any;
  replacedProps: T;
}

export interface InputSubStore {
  [input_hash: string]: InputState<any>;
};

export interface OutputState<T extends {}> {
  value: any;
  parameters: T;
}

export interface OutputSubStore {
  [input_hash: string]: OutputState<any>;
};

export interface MATTAction {
  type: string;
  [key: string]: any;
};

export interface MATTStore {
  ui: UIStore;
  inputs: InputSubStore;
  outputs: OutputSubStore;
};

export const INITIAL_STORE: MATTStore = {
  ui: INITIAL_UI_STORE,
  inputs: {},
  outputs: {}
}

const rootReducer = combineReducers({
  ui: uiReducer
})

export default createStore(rootReducer);