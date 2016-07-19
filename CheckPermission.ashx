<%@ WebHandler Language="C#" Class="CheckPermission" %>

using System;
using System.Configuration;
using System.Web;
using System.Linq;
using Darren.Common.Entities;
using Darren.Common.Helper;
using Darren.Common.Permission;
using BllPermission = PermissionSystem.BLL.CsPermission;
using ModelPermission = PermissionSystem.Model.CsPermission;

public class CheckPermission : IHttpHandler
{
    private readonly BllPermission _bllPermission = new BllPermission();
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "text/plain";

        Boolean disabledAll = false;
        if (ConfigurationManager.AppSettings["DisableAllLicenses"] != null)
        {
            Boolean.TryParse(ConfigurationManager.AppSettings["DisableAllLicenses"], out disabledAll);
        }

        if (disabledAll)
        {
            WriteFailedResult(context, "disabled");
            return;
        }

        var propertyId = context.Request["propertyId"] ?? "0";
        Int32 id;
        if (!Int32.TryParse(propertyId, out id))
        {
            LogHelper.WriteLog("CheckPermissionFailed", String.Format("Property id[{0}] is not right", propertyId));
            WriteFailedResult(context, String.Format("Property id[{0}] is not right", propertyId));
            return;
        }

        var permission = _bllPermission.GetModel(id);
        if (permission == null)
        {
            LogHelper.WriteLog("CheckPermissionFailed", String.Format("Property id[{0}] didn't find", id));
            WriteFailedResult(context, String.Format("Property id[{0}] didn't find", id));
            return;
        }

        var securityBuilder = new SecurityBuilder
        {
            DesKey = permission.DesKey,
            Md5Key = permission.Md5Key,
        };
        var result = securityBuilder.GetRequestResult(context.Request);
        if (!result.IsSuccess)
        {
            LogHelper.WriteLog("CheckPermissionFailed", String.Format("id:{0},msg:{1}", id, result.Msg));
            WriteFailedResult(context, result.Msg);
            return;
        }

        //var cpu = (result.Data.ContainsKey("cpu") ? result.Data["cpu"] : "").Split(new[] { '|' }, StringSplitOptions.RemoveEmptyEntries).ToDictionary(t => t);
        //var harddisk = (result.Data.ContainsKey("harddisk") ? result.Data["harddisk"] : "").Split(new[] { '|' }, StringSplitOptions.RemoveEmptyEntries).ToDictionary(t => t);
        //if (!cpu.ContainsKey(permission.CPU) || !harddisk.ContainsKey(permission.HardDisk))
        //{
        //    LogHelper.WriteLog("CheckPermissionFailed", String.Format("id:{4},cpu or harddisk is not right.cpu: {0}, cpu in db:{1}, harddisk:{2},harddisk in db:{3}", result.Data.ContainsKey("cpu") ? result.Data["cpu"] : "", permission.CPU, result.Data.ContainsKey("harddisk") ? result.Data["harddisk"] : "", permission.HardDisk, id));
        //    WriteFailedResult(context, String.Format("cpu or harddisk is not right.cpu: {0}, cpu in db:{1}, harddisk:{2},harddisk in db:{3}", result.Data.ContainsKey("cpu") ? result.Data["cpu"] : "", permission.CPU, result.Data.ContainsKey("harddisk") ? result.Data["harddisk"] : "", permission.HardDisk));
        //    return;
        //}

        if (!permission.Enabled)
        {
            LogHelper.WriteLog("CheckPermissionFailed", String.Format("id:{0} has been disabled", id));
            WriteFailedResult(context, String.Format("it has been disabled"));
            return;
        }

        if (permission.ExpiredDate <= DateTime.Now)
        {
            LogHelper.WriteLog("CheckPermissionFailed", String.Format("id:{0} was expired", id));
            WriteFailedResult(context, String.Format("it was expired"));
            return;
        }

        WriteSuccessResult(context);
    }

    private static void WriteFailedResult(HttpContext context, String msg)
    {
        context.Response.Write(JSONHelper.ToJSON(new CheckPermissionResponse(false) { Msg = msg }));
        context.Response.End();
    }

    private static void WriteSuccessResult(HttpContext context)
    {
        context.Response.Write(JSONHelper.ToJSON(new CheckPermissionResponse(true) { Msg = "Successful" }));
        context.Response.End();
    }

    public bool IsReusable
    {
        get
        {
            return false;
        }
    }

}