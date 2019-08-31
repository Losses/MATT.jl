import *  as React from 'react';

import store, { HashTable, MATTStore, INITIAL_STORE } from './main';
import FabricComponents from '../components/Fabric';

export type UIStatus = 'success' | 'error' | 'fetching' | 'not-ready';

interface NotReadyUIStore {
  status: 'not-ready';
}

interface FetchingUIStore {
  status: 'fetching';
}

interface ErrorUIStore {
  status: 'error';
  error: string;
}

interface SuccessUIStore {
  status: 'success';
  element: React.ReactElement<any>;
  input_bind: HashTable;
  bind_input: HashTable;
}

export type UIStore = NotReadyUIStore | FetchingUIStore | ErrorUIStore | SuccessUIStore;

export interface MATTAppDefinition {
  jsx_tree: JSXTreeDefinition;
  bind_input: HashTable;
  input_bind: HashTable;
}

export interface JSXTreeDefinition {
  hash: string;
  tag: string;
  props: { [hash: string]: any }
  children?: JSXTreeDefinition[]
}

export const START_FETCH_UI = 'start-fetch-ui';
export const REPORT_FETCH_UI_ERROR = 'report-fetch-ui-error';
export const UPDATE_UI = 'update-ui';

interface StartFetchAction {
  type: 'start-fetch-ui';
}

interface ReportErrorAction {
  type: 'report-fetch-ui-error';
  error: string;
}

interface UpdateUIAction {
  type: 'update-ui';
  element: React.ReactElement<any>;
  input_bind: HashTable;
  bind_input: HashTable;
}

export type UIAction = StartFetchAction | ReportErrorAction | UpdateUIAction;

export const INITIAL_UI_STORE: UIStore = {
  status: 'not-ready'
}

export const uiReducer = (
  store: UIStore = INITIAL_UI_STORE,
  action: UIAction
):UIStore => {
  switch (action.type) {
    case 'start-fetch-ui':
      return {
        status: 'fetching'
      }
    case 'report-fetch-ui-error':
      return {
        status: 'error',
        error: action.error
      }
    case 'update-ui':
      return {
        status: 'success',
        element: action.element,
        input_bind: action.input_bind,
        bind_input: action.bind_input
      }
    default:
      return store
  }
}

const parseJsxTreeDefinition = (x: JSXTreeDefinition): React.ReactElement => {
  const children = x.children ? x.children.map(parseJsxTreeDefinition) : null;
  const props = { ...x.props, __hash: x.hash };

  return React.createElement(FabricComponents[x.tag], props, children)
}

export const getInitialUI = async () => {
  try {
    store.dispatch({ type: 'start-fetch-ui' });
    const ui_response = await fetch('/ui');
    const ui = await ui_response.json() as MATTAppDefinition;

    store.dispatch({
      type: 'update-ui',
      element: parseJsxTreeDefinition(ui.jsx_tree),
      input_bind: ui.input_bind,
      bind_input: ui.bind_input,
    });
  } catch (e) {
    store.dispatch({
      type: 'report-fetch-ui-error',
      error: e.message
    })
  }
}