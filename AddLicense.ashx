<%@ WebHandler Language="C#" Class="AddLicense" %>

using System;
using System.Configuration;
using System.Text;
using System.Web;
using Darren.Common.Entities;
using Darren.Common.Helper;
using BllPermission = PermissionSystem.BLL.CsPermission;
using ModelPermission = PermissionSystem.Model.CsPermission;

public class AddLicense : IHttpHandler
{
    private readonly BllPermission _bllPermission = new BllPermission();
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "text/plain";

        Boolean enabled = false;
        if (ConfigurationManager.AppSettings["enableCreateLicense"] != null)
        {
            Boolean.TryParse(ConfigurationManager.AppSettings["enableCreateLicense"], out enabled);
        }

        if (!enabled)
        {
            WriteFailedResult(context, "disabled");
            return;
        }

        var cpu = context.Request["cpu"] ?? "";
        var harddisk = context.Request["harddisk"] ?? "";
        var system = context.Request["system"] ?? "consume";
        var desKey = Rand.GetRandStr(8);
        var md5Key = Convert.ToBase64String(Encoding.UTF8.GetBytes(Rand.GetRandStr(16)));

        var model = new ModelPermission
        {
            CPU = cpu,
            HardDisk = harddisk,
            RegisterDate = DateTime.Now,
            Enabled = true,
            SystemName = system,
            ExpiredDate = new DateTime(2100, 12, 31),
            DesKey = desKey,
            Md5Key = md5Key
        };
        var id = _bllPermission.Add(model);

        var response = new AddLicenseResponse(true)
        {
            Msg = "Successful",
            DesKey = desKey,
            Md5Key = md5Key,
            PropertyId = id
        };
        WriteSuccessResult(context, response);
    }

    private static void WriteFailedResult(HttpContext context, String msg)
    {
        context.Response.Write(JSONHelper.ToJSON(new AddLicenseResponse(false) { Msg = msg }));
        context.Response.End();
    }

    private static void WriteSuccessResult(HttpContext context, AddLicenseResponse response)
    {
        context.Response.Write(JSONHelper.ToJSON(response));
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