﻿//
// Copyright (c) XSharp B.V.  All Rights Reserved.  
// Licensed under the Apache License, Version 2.0.  
// See License.txt in the project root for license information.
//
using Microsoft.VisualStudio.Shell.TableManager;

namespace XSharp.Project
{
    internal interface IErrorListSinkManager
    {
        /// <summary>
        /// This is called if a new project is added after there is already a sink connected. Informans the sink
        /// of the new source of errors
        /// </summary>
        void AddErrorListFactory(ITableEntriesSnapshotFactory factory);

        /// <summary>
        /// If a project is removed from the solution (unloaded, closed, etc) informans the sink
        /// that the source is no longer available.
        /// </summary>
        void RemoveErrorListFactory(ITableEntriesSnapshotFactory factory);

        /// <summary>
        /// Called when a snapshot changes to have its errors updated by the subscriber. Pass null to have
        /// all the factories updated.
        /// </summary>
        void UpdateSink(ITableEntriesSnapshotFactory factory);
    }
}