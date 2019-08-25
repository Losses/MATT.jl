import { createStore } from 'redux';

export type HashTable = { [hash: string]: string[] };

export interface UISubStore {
  state: 'success' | 'error' | 'fetching' | 'not-ready';
  error?: string;
  element?: React.ReactElement<any>;
  input_bind?: HashTable;
  bind_input?: HashTable;
};

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
  state: any; 
};

export interface MATTStore {
  ui: UISubStore;
  inputs: InputSubStore;
  outputs: OutputSubStore;
};

export const INITIAL_STORE:MATTStore = {
  ui: {
    state: 'not-ready'
  }, 
  inputs: {}, 
  outputs: {}
}

const mainReducer = (store: MATTStore = INITIAL_STORE, action) => {
  return store
}

export default createStore(mainReducer);