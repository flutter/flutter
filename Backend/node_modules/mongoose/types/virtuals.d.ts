declare module 'mongoose' {
    type VirtualPathFunctions<DocType = {}, PathValueType = unknown, TInstanceMethods = {}> = {
      get?: TVirtualPathFN<DocType, PathValueType, TInstanceMethods, PathValueType>;
      set?: TVirtualPathFN<DocType, PathValueType, TInstanceMethods, void>;
      options?: VirtualTypeOptions<HydratedDocument<DocType, TInstanceMethods>, DocType>;
    };

  type TVirtualPathFN<DocType = {}, PathType = unknown, TInstanceMethods = {}, TReturn = unknown> =
    <T = HydratedDocument<DocType, TInstanceMethods>>(this: Document<any, any, DocType> & DocType, value: PathType, virtual: VirtualType<T>, doc: Document<any, any, DocType> & DocType) => TReturn;

    type SchemaOptionsVirtualsPropertyType<DocType = any, VirtualPaths = Record<any, unknown>, TInstanceMethods = {}> = {
      [K in keyof VirtualPaths]: VirtualPathFunctions<IsItRecordAndNotAny<DocType> extends true ? DocType : any, VirtualPaths[K], TInstanceMethods>
    };
}
